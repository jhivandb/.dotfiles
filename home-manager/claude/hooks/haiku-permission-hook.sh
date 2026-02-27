#!/bin/bash
# PreToolUse hook: evaluates Bash commands against configurable patterns
# and uses Claude Haiku to decide whether to allow, deny, or fall through.
#
# Stdin: JSON with tool_name, tool_input.command, etc.
# Stdout: hookSpecificOutput JSON for allow/deny, or nothing for fall-through
# Exit 0 always (fall-through on error/unsure)

set -euo pipefail

CONFIG_FILE="${HOME}/.claude/haiku-filter.json"
LOG_DIR="${PWD}/.claude"
LOG_FILE="${LOG_DIR}/permissions.log"

# Read stdin JSON
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# If no command found, fall through silently
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Load patterns from config
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

PATTERNS=$(jq -r '.patterns[]' "$CONFIG_FILE" 2>/dev/null)
if [[ -z "$PATTERNS" ]]; then
  exit 0
fi

# Check if command matches any pattern
MATCHED=false
while IFS= read -r pattern; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    MATCHED=true
    break
  fi
done <<< "$PATTERNS"

# If no pattern matched, fall through silently (not logged)
if [[ "$MATCHED" != "true" ]]; then
  exit 0
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build the prompt for Haiku
PROMPT="You are a security evaluator for CLI commands. Evaluate whether this command is non-destructive and safe to execute automatically.

Command: ${COMMAND}

Rules:
- ALLOW: Read-only operations, listing, querying, fetching data, non-destructive actions
- DENY: Destructive operations (delete, force push, drop, truncate), privilege escalation, credential exposure
- UNSURE: Anything you are not confident about

Respond with exactly one word on the first line: ALLOW, DENY, or UNSURE
Then a brief reason on the second line."

# Call Haiku via claude CLI pipe mode
HAIKU_RESPONSE=$(echo "$PROMPT" | claude -p --model haiku 2>/dev/null) || {
  # If claude CLI fails, log and fall through
  echo "[$TIMESTAMP] ERROR | $COMMAND" >> "$LOG_FILE"
  exit 0
}

# Parse the first line for the decision
DECISION=$(echo "$HAIKU_RESPONSE" | head -1 | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
REASON=$(echo "$HAIKU_RESPONSE" | tail -n +2 | tr '\n' ' ' | sed 's/[[:space:]]*$//')

# Log the decision
echo "[$TIMESTAMP] $DECISION | $COMMAND" >> "$LOG_FILE"

case "$DECISION" in
  ALLOW)
    cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Haiku: ${REASON//\"/\\\"}"
  }
}
ENDJSON
    ;;
  DENY)
    cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Haiku: ${REASON//\"/\\\"}"
  }
}
ENDJSON
    ;;
  *)
    # UNSURE or anything unexpected: silent fall-through
    exit 0
    ;;
esac
