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

# Verify this is a Bash tool call
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

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

# Stage 2: Destructive keyword scan
# If the command contains destructive keywords, fall through to user prompt
DESTRUCTIVE_PATTERN="\b(delete|remove|destroy|drop|clear|wipe|purge|forget|erase|reset|force|push|deploy|publish|execute|eval|merge|rebase|truncate|kill)\b"
if echo "$COMMAND" | grep -qiE "$DESTRUCTIVE_PATTERN"; then
  mkdir -p "$LOG_DIR"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$TIMESTAMP] DESTRUCTIVE | $COMMAND" >> "$LOG_FILE"
  exit 0
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build the prompt for Haiku
PROMPT="You are a security evaluator for CLI commands. Evaluate whether this command is safe to auto-approve without user confirmation.

Command: ${COMMAND}

SAFE patterns (auto-approve if the command matches these behaviors):
- get, list, read, retrieve, fetch, search, find, query
- check, status, health, stats, analyze
- view, show, describe, inspect
- Additive-only operations (store, remember, ingest)
- Context/summary retrieval

Rules:
- ALLOW: Command is clearly read-only, informational, or additive-only
- UNSURE: Anything you are not fully confident is safe

You MUST respond conservatively. If there is ANY doubt, respond UNSURE.
Respond with exactly one word on the first line: ALLOW or UNSURE
Then a brief reason on the second line."

# Call Haiku via claude CLI pipe mode
# --setting-sources "" prevents inheriting hooks from ~/.claude/settings.json
# --max-turns 1 ensures single response, --no-session-persistence avoids writing session files
HAIKU_RESPONSE=$(echo "$PROMPT" | env -u CLAUDECODE claude -p \
  --model haiku \
  --setting-sources "" \
  --max-turns 1 \
  --no-session-persistence \
  2>/dev/null) || {
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
    jq -n \
      --arg reason "Haiku: ${REASON}" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", permissionDecisionReason: $reason}}'
    ;;
  *)
    # UNSURE or anything unexpected: silent fall-through (user gets prompted)
    exit 0
    ;;
esac
