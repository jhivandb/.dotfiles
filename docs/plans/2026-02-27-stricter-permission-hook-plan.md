# Stricter Permission Hook Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign haiku-permission-hook.sh to be a strict auto-approver with destructive keyword pre-filtering and enriched Haiku prompt.

**Architecture:** Three-stage evaluation: pre-filter (haiku-filter.json) → destructive keyword scan (hardcoded, grep -wiE) → Haiku evaluation (enriched prompt, ALLOW or fall-through only). No deny decisions ever.

**Tech Stack:** Bash, jq, grep, claude CLI (pipe mode)

---

### Task 1: Add destructive keyword scan

**Files:**
- Modify: `home-manager/claude/hooks/haiku-permission-hook.sh:54` (insert after pre-filter match check)

**Step 1: Add destructive keywords array and grep check after line 54**

Insert this block between the pre-filter match check (line 54) and the log directory setup (line 57):

```bash
# Stage 2: Destructive keyword scan
# If the command contains destructive keywords, fall through to user prompt
DESTRUCTIVE_PATTERN="\\b(delete|remove|destroy|drop|clear|wipe|purge|forget|erase|reset|force|push|deploy|publish|execute|eval|merge|rebase|truncate|kill)\\b"
if echo "$COMMAND" | grep -qiE "$DESTRUCTIVE_PATTERN"; then
  mkdir -p "$LOG_DIR"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$TIMESTAMP] DESTRUCTIVE | $COMMAND" >> "$LOG_FILE"
  exit 0
fi
```

**Step 2: Verify the keyword scan works**

Run: `echo '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 42"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: No stdout output (fall-through), exit 0. Check `.claude/permissions.log` for `DESTRUCTIVE | gh pr merge 42`.

Run: `echo '{"tool_name":"Bash","tool_input":{"command":"gh api repos/owner/repo --jq .name"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: Command proceeds to Haiku evaluation (not caught by destructive scan since "api" is not destructive).

**Step 3: Commit**

```bash
git add home-manager/claude/hooks/haiku-permission-hook.sh
git commit -m "Add destructive keyword scan to permission hook"
```

---

### Task 2: Replace Haiku prompt with enriched version

**Files:**
- Modify: `home-manager/claude/hooks/haiku-permission-hook.sh:62-72` (replace PROMPT variable)

**Step 1: Replace the PROMPT string**

Replace the current prompt (lines 62-72) with:

```bash
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
```

**Step 2: Commit**

```bash
git add home-manager/claude/hooks/haiku-permission-hook.sh
git commit -m "Enrich Haiku prompt with safe patterns and conservative bias"
```

---

### Task 3: Remove DENY case, simplify to ALLOW-or-fallthrough

**Files:**
- Modify: `home-manager/claude/hooks/haiku-permission-hook.sh:95-110` (replace case statement)

**Step 1: Replace the case statement**

Replace the current case block (lines 95-110) with:

```bash
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
```

**Step 2: Commit**

```bash
git add home-manager/claude/hooks/haiku-permission-hook.sh
git commit -m "Remove deny case, hook only auto-approves or falls through"
```

---

### Task 4: Update script header comments

**Files:**
- Modify: `home-manager/claude/hooks/haiku-permission-hook.sh:1-7` (update header)

**Step 1: Replace header comments**

Replace lines 1-7 with:

```bash
#!/bin/bash
# PreToolUse hook: auto-approves safe Bash commands, falls through for everything else.
#
# Three-stage evaluation:
#   1. Pre-filter: haiku-filter.json patterns gate which commands enter evaluation
#   2. Destructive keyword scan: commands with destructive words fall through (user prompted)
#   3. Haiku evaluation: enriched prompt decides ALLOW (auto-approve) or fall-through
#
# Stdin: JSON with tool_name, tool_input.command, etc.
# Stdout: hookSpecificOutput JSON for allow, or nothing for fall-through
# Exit 0 always (fall-through on error/unsure/destructive)
```

**Step 2: Commit**

```bash
git add home-manager/claude/hooks/haiku-permission-hook.sh
git commit -m "Update hook header to reflect auto-approver design"
```

---

### Task 5: Smoke test the full flow

**Step 1: Test destructive command falls through**

Run: `echo '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 42"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: No stdout (fall-through). Log shows `DESTRUCTIVE | gh pr merge 42`.

**Step 2: Test safe command gets auto-approved**

Run: `echo '{"tool_name":"Bash","tool_input":{"command":"gh api repos/owner/repo --jq .name"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: JSON stdout with `permissionDecision: "allow"`. Log shows `ALLOW | gh api ...`.

**Step 3: Test non-matching command falls through silently**

Run: `echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: No stdout (fall-through). No log entry (didn't match pre-filter).

**Step 4: Test non-Bash tool falls through silently**

Run: `echo '{"tool_name":"Read","tool_input":{"file":"/tmp/test"}}' | bash home-manager/claude/hooks/haiku-permission-hook.sh`
Expected: No stdout (fall-through). No log entry.

**Step 5: Apply Home Manager and verify symlinks**

Run: `home-manager switch --flake .`
Then verify: `cat ~/.claude/hooks/haiku-permission-hook.sh` matches the updated script.
