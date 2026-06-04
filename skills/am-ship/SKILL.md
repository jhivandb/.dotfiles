---
name: am-ship
description: Git workflow and commit conventions for the agent-manager repo (canonical upstream wso2/agent-manager). Trigger when working in any clone or git worktree of agent-manager — identify by a git remote whose URL ends in /agent-manager, NOT by filesystem path or folder name — AND the task involves commits, commit messages, git history, pushing, shipping, or PRs. Also invoke explicitly via `/am-ship`.
---

# am-ship — agent-manager git workflow

Workflow skill for the `agent-manager` repo. Applies to **any clone or linked worktree** of agent-manager, identified by its git remotes — a remote whose URL ends in `/agent-manager` (the canonical upstream is `wso2/agent-manager`). Independent of filesystem path, machine, and worktree folder name: worktrees may live anywhere (e.g. `/private/tmp/...`) and need not contain "agent-manager" in their name. The preflight script (step 1) confirms identity for you.

## Repo facts

Remote *names* vary per clone — don't assume them. Run `git remote -v` and classify by URL:

| Role | How to identify (by URL) | Push from this skill? |
|---|---|---|
| **Canonical upstream** | `…/wso2/agent-manager` (conventionally `upstream`) | **NEVER** — read-only canonical |
| **Your fork** | your own remote, conventionally `origin` — URL is `<your-gh-user>/agent-manager` and not wso2 | YES — `git push -u origin HEAD` |
| **Collaborator fork** | any other `…/agent-manager` remote (a teammate's fork) | only if the user explicitly names it |

`main` is a shared branch — treat it as **never-push** and always work on a feature branch. Depending on the clone, `main` may track the wso2 upstream *or* your fork; don't rely on it. The preflight script reports the actual tracking ref and refuses any push whose effective target isn't your own fork.

## Workflow

Run sequentially. Stop and ask if anything is ambiguous.

### 1. Verify the push target is safe

Run the bundled preflight script. It identifies the repo by remote URL, then checks branch name, tracking ref, and push config in one shot. The script lives in this skill's own directory — use the absolute path shown as **"Base directory for this skill"** in the header when this skill loads:

```bash
"<skill-base-dir>/scripts/preflight.sh"
```

Exit codes: `0` = safe; `2` = a push-safety violation (read the `WARN:` lines); `1` = can't run / not the agent-manager repo.

It refuses if: branch is `main`; the canonical upstream (`wso2/agent-manager`) is the effective push target; or a bare `git push` would reach anything other than your fork (a collaborator's fork, a raw-URL tracking config, etc.). On failure, tell the user where the bare push would land and ask which remote+branch they want (almost always `origin/<feature-branch>`). Offer to `git switch -c <new-branch>` off the current commit.

If the script can't be located or run (other host, different install), fall back to:

```bash
git remote -v                                                        # which remote is wso2 vs your fork
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "(no upstream tracking set)"
```

…and apply the same rules manually: never push to the wso2 remote; push only to your own fork.

If no upstream tracking is set, that's fine — step 6 will set it to `origin/<branch>` with `-u`.

### 2. Inspect the diff

```bash
git status
git diff --stat
git diff               # or scoped: git diff -- <paths>
```

Use the diff to decide which generators apply (next step). Do not skip this — generators are slow and some require infra, so running blindly wastes time.

### 3. Run the relevant generators

The repo has many code-gen targets. Run only what the diff implies. The top-level `Makefile` delegates into `agent-manager-service/Makefile`; mirror that with `cd agent-manager-service && make ...`.

| Diff touches | Run from repo root |
|---|---|
| `agent-manager-service/docs/api_v1_openapi.yaml` (the `am` CLI's OpenAPI spec) | `make am-gen-client` |
| Any Go in `agent-manager-service/` with wire bindings (`*wire*.go`) | `cd agent-manager-service && make wire` |
| Any other Go in `agent-manager-service/` (handlers, models) | `cd agent-manager-service && make codegen && make fmt` |
| `agent-manager-service/docs/*openapi*.yaml` | `cd agent-manager-service && make spec` |
| Files under `agent-manager-service/.../oc/`, `.../observer/`, `.../api-platform/` clients | `cd agent-manager-service && make gen-oc-client` / `make gen-observer-client` / `make gen-api-platform-client` (only the relevant one) |
| Evaluator code or `libs/amp-evaluation/` | `make gen-eval-artifacts` (regenerates Go catalog + console TS models) |
| Migrations under `agent-manager-service/migrations/` | mention `make dev-migrate` to user — DO NOT auto-run (needs docker-compose DB up) |
| `cmd/am`, `internal/am` only with no spec change | nothing to generate |
| Console-only changes (`console/`) | nothing here; the console has its own `rush build` flow |
| `python-instrumentation-provider/`, `traces-observer-service/`, `evaluation-job/` | no gen targets in those Makefiles |

After running generators, re-run `git status` / `git diff --stat`. If generated files changed, stage them with the rest of the commit. If nothing changed, the diff was already up-to-date — note that and continue.

### 4. Validate (offer, don't gate)

Pick by area touched. Offer to run; gate the commit only if the user asks. If a command needs infra (`docker-compose` DB, network, missing tools), surface the exact command and let the user decide — don't run blindly.

| Diff touches | Validate with |
|---|---|
| Root Go CLI (`cmd/`, `internal/am/`, root `go.mod`) | `gofmt` touched files; `go mod tidy` if deps changed; `go test ./...` |
| `agent-manager-service/` | `cd agent-manager-service && make fmt && make lint && make test` (`test`/`dev-test` needs DB) |
| `console/` | `make -C console build` or targeted `rush lint` / `rush test`; see `console/AGENTS.md` |
| `documentation/` | `make -C documentation build` |
| `evaluation-job/` | `make -C evaluation-job lint format-check type-check test` |
| `traces-observer-service/` | `cd traces-observer-service && make fmt && make lint && make test` |
| `python-instrumentation-provider/` | no Makefile targets — defer to module tooling |

### 5. Commit using repo style

Sample the prevailing style first:

```bash
git log --pretty=format:"%s" --no-merges -30
```

Default commit-message style in this repo (the history is consistently this — sample with the command above to confirm):
- Imperative mood verb first
- **First letter capitalized**
- **No trailing period**
- ~50–72 chars on a single line
- No conventional-commit prefix (`feat:`, `fix:`, `chore:`) — the repo only uses `docs:` for release-doc commits
- No body unless the change really needs explaining

Examples to imitate:
- `Add am agent list/get/delete subcommands`
- `Wire am login through factory and JSON envelopes`
- `Fix invalid gateway being picked when deploying llm proxy`
- `Refactor SpanDetailsPanel to improve tab selection logic`

Do NOT include `Co-Authored-By: Claude` or `Generated with Claude Code` trailers — no commit in this repo has them and they would stand out in a PR.

Stage explicitly (avoid `git add -A` / `git add .`):

```bash
git add <specific files>
git commit -m "<message>"
```

If pre-commit hooks fail, fix the issue and create a NEW commit — never `--amend` and never `--no-verify`.

### 6. Push to your fork

```bash
git push -u origin HEAD
```

The `-u` is important: it pins the branch to `origin/<branch>` so future `git push` calls don't fall back to whatever tracking config was inherited (a `main` that tracks the wso2 upstream, or a branch whose remote is a teammate's fork). This is the structural defense behind the preflight check.

If the user explicitly asks to push to a collaborator's fork, push to that remote by name (`git push -u <remote> HEAD`). Never push to the wso2 remote. If somehow on `main`, switch to a feature branch first (`git switch -c <name>`) — do not push `main` to any remote.

### 7. PR (only when the user asks)

PRs target `wso2/agent-manager` (the canonical upstream). The `--head` owner is your fork's GitHub user — derive it from `origin` instead of hardcoding it:

```bash
owner=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/agent-manager(\.git)?$#\1#')
gh pr create --repo wso2/agent-manager --base main --head "$owner:<branch>" --title "..." --body "..."
```

The repo has a heavy `pull_request_template.md` with these sections: Purpose, Goals, Approach, User stories, Release note, Documentation, Training, Certification, Marketing, Automation tests (Unit + Integration), Security checks (3 yes/no boxes), Samples, Related PRs, Migrations, Test environment, Learning. Fill the sections that apply; for the rest write `N/A` with a one-line reason. Don't drop sections.

For the Security checks block, the three questions are literal — answer each yes/no based on the actual change.

## Anti-patterns to avoid

- Bare `git push` from `main`, or from any branch whose tracking points at the wso2 upstream or a teammate's fork — always push explicitly with `git push -u origin HEAD`.
- Running a sub-Makefile target without `cd`ing — the top-level Makefile delegates with `cd agent-manager-service && make ...`; mirror that pattern.
- Adding `Co-Authored-By` / Claude trailers (zero existing commits use them).
- `git commit --amend` or `git push --force` on a branch already pushed, without asking.
- Auto-running `make dev-migrate` or `make test` (need docker-compose DB up — surface to user, don't run blindly).
- Lowercase-first-letter or `feat:`/`chore:` prefixes in commit messages — they'd stick out.
- `git add -A` / `git add .` — stage explicit paths so generated stragglers or stray files don't sneak in.

## Quick command reference

```bash
# Safety check (preferred) — script is in this skill's base directory
"<skill-base-dir>/scripts/preflight.sh"

# Safety check (fallback)
git remote -v
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null

# Sample commit style
git log --pretty=format:"%s" --no-merges -30

# Most common generators
make am-gen-client                                  # OpenAPI -> am CLI client
cd agent-manager-service && make codegen && make fmt
cd agent-manager-service && make wire
make gen-eval-artifacts

# Push (always with -u to pin to origin)
git push -u origin HEAD
```
