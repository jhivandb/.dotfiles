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

## Lifecycle: Project → Agent → Build

### Create project

```bash
amctl project create <name> --display-name "Human Name"
```

### Create agent

Two build types, each with required flags:

**Buildpack:**
```bash
amctl agent --help
amctl agent create <name> --project <proj> \
  --display-name "Human Name" --subtype chat-api \
  --repo-url <url> --repo-branch main --repo-path /path/to/app \
  --build-type buildpack --language python --language-version "3.11" \
  --run-command "python -m uvicorn app:app --host 0.0.0.0 --port 8000"
```

**Docker:**
```bash
amctl agent create <name> --project <proj> \
  --display-name "Human Name" --subtype chat-api \
  --repo-url <url> --repo-branch main --repo-path /path/to/app \
  --build-type docker --dockerfile Dockerfile
```

For `--subtype custom-api`, also pass `--port`, `--base-path`, `--openapi-spec`. Do not pass `--port` for `chat-api`.

Agent create auto-triggers a build.
Build logs may be empty briefly while the build initializes — wait and retry.

### Builds

Builds live under `amctl agent build`, not a top-level command. The agent name is a **positional argument** (not `--agent`).

```bash
amctl agent build list <agent> --project <proj>
amctl agent build logs <agent> <build-name> --project <proj>
amctl agent build create <agent> --project <proj>
```

Use `--json` on `build list` to get both `buildId` (UUID) and `buildName`. Subsequent commands (logs, get) require the **build name**, not the UUID.

## Global flags

`--json` — JSON envelope output (all commands). Errors include `code`, `message`, `additionalData.details`.
`--org <name>` — override active org for one command.
`--project <name>` — override linked project for one command (agent/build commands).


## Validation errors

Missing or invalid flags produce a batched error listing all violations at once:

```
X invalid flags
    name argument is required
    --display-name is required
    --build-type is required for internal provisioning
```

Read the full list, fix all issues, then retry — don't fix one at a time.
