---
name: am-ops
description: Operate the amctl CLI to manage agent-manager resources. Use when the user asks to create, deploy, build, delete, or inspect projects and agents, set up context/linking, or check build status. Triggers on requests like "create a project", "deploy an agent", "check build logs", "link this directory", "list my agents".
metadata:
  internal: true
---

# am-ops — Operating amctl

Drive `amctl` to manage agent-manager resources. Assumes authenticated (`amctl login` already done).

## Preflight

```bash
amctl --help
amctl context show
```

If auth error ("re-run `amctl login`"): tell user to run `! amctl login` — do not attempt login yourself.
If connection refused: control plane is down, stop and tell user.

## Global flags

`--json` — JSON envelope output (all commands). Errors include `code`, `message`, `additionalData.details`.
`--org <name>` — override active org for one command.
`--project <name>` — override linked project for one command (agent/build commands).
