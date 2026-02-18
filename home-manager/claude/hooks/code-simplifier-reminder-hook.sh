#!/bin/bash
# PostToolUse hook that reminds to use code-simplifier after write operations
#
# This hook fires after Write or Edit tool calls and reminds Claude
# to use the code-simplifier agent once all write actions are complete.
#
# Configure in settings.json under hooks.PostToolUse with matcher: "Write" and "Edit"

cat <<'EOF'
REMINDER: Code Simplification

After completing ALL write/edit actions for this task, use the code-simplifier agent
to review and clean up the modified code.

Action required when task writes are complete:
→ Use Task tool with subagent_type="code-simplifier:code-simplifier" targeting the files you modified

Do NOT invoke code-simplifier after every single edit. Wait until the implementation
is functionally complete, then run it once on all affected files.
EOF
