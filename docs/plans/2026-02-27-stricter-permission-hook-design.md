# Stricter Permission Hook Design

**Date:** 2026-02-27
**Status:** Approved
**File:** `home-manager/claude/hooks/haiku-permission-hook.sh`

## Goal

Redesign the haiku-permission-hook to be a strict **auto-approver** rather than an allow/deny gatekeeper. Safe commands get auto-approved; everything else falls through to Claude Code's normal permission prompt (user decides).

## Design Decisions

- **No deny** — the hook never blocks commands. It either auto-approves or falls through.
- **Destructive keywords hardcoded** — no separate config file, lives in the script.
- **Word-boundary grep** — simple `grep -wiE` for destructive keyword matching.
- **Haiku only for non-obvious commands** — destructive commands skip Haiku entirely.
- **Enriched Haiku prompt** — safe patterns list included for better decision-making.

## Three-Stage Evaluation Flow

```
Command arrives via stdin
        │
        ▼
┌─────────────────────┐
│ Is it a Bash tool?  │──no──▶ exit 0 (fall-through)
└─────────────────────┘
        │ yes
        ▼
┌─────────────────────┐
│ Matches pre-filter   │──no──▶ exit 0 (fall-through)
│ (haiku-filter.json)  │
└─────────────────────┘
        │ yes
        ▼
┌──────────────────────────┐
│ Destructive keyword scan │──yes──▶ exit 0 (fall-through, user prompted)
│ (word-boundary grep)     │         + log as DESTRUCTIVE
└──────────────────────────┘
        │ no destructive words
        ▼
┌─────────────────────┐
│ Haiku evaluation     │
│ (enriched prompt)    │
└─────────────────────┘
        │
   ┌────┴────┐
   ▼         ▼
 ALLOW    fall-through
 (auto-    (user
 approve)  prompted)
```

### Stage 1: Pre-filter (unchanged)

`haiku-filter.json` patterns gate which commands enter evaluation at all. Non-matching commands fall through silently.

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

### Stage 2: Destructive Keyword Scan

Word-boundary grep (`grep -wiE`) against the bash command text. If any keyword matches, fall through immediately — no Haiku call, user gets prompted.

```bash
DESTRUCTIVE_KEYWORDS=(
  delete remove destroy drop clear wipe purge
  forget erase reset force push deploy publish
  execute eval merge rebase truncate kill
)
```

### Stage 3: Haiku Evaluation (enriched prompt)

Commands that pass both gates are sent to Haiku with an enriched prompt:

```
You are a security evaluator for CLI commands. Evaluate whether
this command is safe to auto-approve without user confirmation.

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
Then a brief reason on the second line.
```

Haiku returns ALLOW (auto-approve) or UNSURE/anything else (fall-through).

## Logging

Log format with updated decision labels:

```
[timestamp] ALLOW | command        # Haiku approved, auto-approved
[timestamp] DESTRUCTIVE | command  # Keyword scan caught, fell through
[timestamp] UNSURE | command       # Haiku unsure, fell through
[timestamp] ERROR | command        # Haiku call failed, fell through
```

## Output Behavior

- `ALLOW` → emit `permissionDecision: "allow"` JSON with reason
- Everything else → no stdout output, exit 0 (fall-through to normal permission prompt)

## What Doesn't Change

- `haiku-filter.json` structure and patterns
- `settings.json` hook registration
- Hook file location and deployment via Home Manager symlinks
- Overall script structure (stdin JSON parsing, tool_name guard, error handling)

## Reference

Inspired by [mcp-memory-service permission-request.js](https://github.com/doobidoo/mcp-memory-service/blob/main/claude-hooks/core/permission-request.js) which uses deterministic pattern matching with destructive-first, safe-second evaluation order.
