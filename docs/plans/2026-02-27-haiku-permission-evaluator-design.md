# Haiku Permission Evaluator

## Problem

Claude Code's permission prompts interrupt flow for non-destructive commands. We want an automated evaluator that approves safe commands and only escalates to the user when unsure.

## Solution

A `PreToolUse` hook on `Bash` that pre-filters commands against configurable regex patterns, sends matching commands to Claude Haiku via `claude -p --model haiku` for safety evaluation, and logs every decision.

## Architecture

```
PreToolUse (Bash) -> haiku-permission-hook.sh
                         |
                         +-- Read stdin JSON, extract command
                         +-- Load patterns from haiku-filter.json
                         |
                         +-- Command matches pattern?
                         |   NO  -> exit 0 (silent fall-through)
                         |   YES -> pipe to claude -p --model haiku
                         |           |
                         |           +-- Haiku says ALLOW  -> output allow JSON
                         |           +-- Haiku says DENY   -> output deny JSON
                         |           +-- Haiku says UNSURE -> exit 0, no output (silent fall-through)
                         |
                         +-- Log command + decision to .claude/permissions.log
```

## Files

All source files live in `home-manager/claude/` (symlinked to `~/.claude/`):

| File | Path (in dotfiles repo) | Purpose |
|------|------------------------|---------|
| Hook script | `home-manager/claude/hooks/haiku-permission-hook.sh` | The PreToolUse hook |
| Filter config | `home-manager/claude/haiku-filter.json` | Regex patterns for pre-filtering |
| Log file | `.claude/permissions.log` (per-project, not in repo) | Audit log |

## Config Format (haiku-filter.json)

```json
{
  "patterns": [
    "^gh (api|pr|issue|release|workflow)",
    "&&",
    "\\|\\|",
    "\\|",
    ";"
  ]
}
```

Patterns are regex. If any pattern matches the command string, the command is routed to Haiku for evaluation.

## Hook Script Behavior

1. Read JSON from stdin, extract `tool_input.command`
2. Load patterns from `~/.claude/haiku-filter.json`
3. Check command against each pattern
4. If no match: exit 0 with no output (silent fall-through, not logged)
5. If match: pipe command to `claude -p --model haiku` with a system prompt
6. Parse Haiku's response (ALLOW / DENY / UNSURE)
7. If ALLOW or DENY: output appropriate `hookSpecificOutput` JSON
8. If UNSURE: exit 0 with no output (silent fall-through to normal permission prompt)
9. Append entry to `.claude/permissions.log`

## Haiku System Prompt

Instructs Haiku to:
- Evaluate whether the command is non-destructive and safe
- Respond with exactly ALLOW, DENY, or UNSURE
- Include a brief reason on the same line after the decision
- Be conservative: if uncertain, respond UNSURE

## Hook Output Format

**ALLOW:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Haiku: <reason>"
  }
}
```

**DENY:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Haiku: <reason>"
  }
}
```

**UNSURE (silent fall-through to user):**

Exit 0 with no stdout. This lets the normal permission prompt appear per the Claude Code hook contract.

## Log Format

```
[2026-02-27T14:30:00Z] ALLOW | gh api repos/org/repo/pulls
[2026-02-27T14:30:05Z] UNSURE | gh api -X DELETE repos/org/repo/branches/feature
```

Only commands that match filter patterns are logged. Non-matching commands are not logged.

## Settings.json Addition

Add to the existing `hooks` object:

```json
"PreToolUse": [{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "command": "~/.claude/hooks/haiku-permission-hook.sh"
  }]
}]
```

## Home Manager Wiring

The hook script and config file are symlinked via `home.nix` alongside existing hooks, using the same `mkHomeSymlinks` mechanism.
