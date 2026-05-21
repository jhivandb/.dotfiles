---
name: am-dx
description: Use when testing the amctl CLI developer experience. Autonomously exercises the full agent dev workflow against a running local environment, evaluates UX across five dimensions, and produces a narrative report. Invoke explicitly via /am-dx.
---

# am-dx — CLI Developer Experience Testing

Autonomous DX testing for `amctl`. Runs through the agent dev workflow as a real user would, evaluates the experience, and reports findings as a narrative with a structured findings table.

## Prerequisites

- Local agent-manager service is running
- `amctl` is on PATH
- User is already logged in (do NOT attempt login)
- Do NOT read internal source code unless a specific bug demands it — test as an outside user

## Workflow

Run from the current working directory.

```dot
digraph dx_test {
    rankdir=TB;
    discover [label="Phase 1: Discover commands" shape=box];
    context [label="Phase 2: Context setup" shape=box];
    create [label="Phase 3: Create resources" shape=box];
    verify [label="Phase 4: Verify resources" shape=box];
    cleanup [label="Phase 5: Cleanup" shape=box];
    report [label="Phase 6: Report" shape=box];
    blocker [label="Blocking error?" shape=diamond];

    discover -> context;
    context -> blocker;
    blocker -> create [label="no"];
    blocker -> report [label="yes — report immediately"];
    create -> verify;
    verify -> cleanup;
    cleanup -> report;
}
```

### Phase 1: Discovery

Scan what commands exist right now. Run `amctl --help` and recurse into subcommands. Do NOT hardcode a command list — adapt to whatever is available at invocation time.

Record the command tree for use in the consistency evaluation.

### Phase 2: Context Setup

```bash
amctl context show
amctl context org list
amctl context org use <pick-local>
amctl context instance list
amctl context instance use <pick-local>
amctl context show   # verify it stuck
```

**Edge probes:**
- `amctl context org use nonexistent-org`
- `amctl context instance use ""`
- `amctl context show` with no context set (if possible to clear)

### Phase 3: Create Resources

```bash
amctl project create dx-test-<timestamp>
```

Always attempt to deploy a sample agent. Discover required flags from `amctl agent deploy --help` and fill with plausible dummy values. If deploy fails, record the error verbatim — that's a finding.

Use identifiable test names prefixed with `dx-test-` so cleanup is unambiguous.

**Edge probes:**
- Create with missing required flags
- Create with duplicate name
- Create with invalid characters in name

### Phase 4: Verify

```bash
amctl project list
amctl project get <id-from-create>
amctl agent list
amctl agent get <id>   # if agent was created
```

**Edge probes:**
- `amctl project get nonexistent-id`
- `amctl agent get ""`
- `amctl project list` output format vs `agent list` (consistency check)

### Phase 5: Cleanup

```bash
amctl agent delete <id>    # if agent was created
amctl project delete <id>
```

Verify cleanup by re-listing. Confirm resources are gone.

**Edge probes:**
- Delete already-deleted resource
- Delete with invalid ID

### Phase 6: Report

Write findings to `DX.md` in the current working directory.

#### Narrative (primary)

Write as a first-person walkthrough. Cover the full session chronologically:

> "I started by checking what commands were available. Running `amctl --help` showed..."

Weave observations naturally into the story. Call out friction, confusion, delight, and suggestions as they arise. The narrative should read like a UX researcher's session notes.

#### Findings Table (supplementary)

Prioritize every finding as P0, P1, or P2 (see Severity Levels below).

| Priority | Category | Command | Finding | Suggested Fix |
|----------|----------|---------|---------|---------------|
| P0 | ... | ... | ... | ... |

## Evaluation Dimensions

Assess every command against all five:

### 1. Output Clarity
- Are success messages informative or uselessly silent?
- Are error messages helpful? Do they suggest what to do next?
- Is important info (IDs, names, status) surfaced prominently?
- Is JSON output well-structured when `--json` is used?

### 2. Consistency
- Do similar commands use the same flag names?
- Is output format uniform across command groups (tables, columns, spacing)?
- Are exit codes consistent (0 success, non-zero failure)?
- Do CRUD commands follow the same patterns?

### 3. Flow Friction
- Are there unexpected interactive prompts?
- Are defaults sensible? Can you skip optional flags?
- Is the number of steps reasonable for common operations?
- Does the CLI guide you toward the next action?

### 4. Edge Cases
- Graceful handling of invalid input?
- Helpful errors that point toward the fix?
- No crashes, panics, or stack traces on bad input?
- Idempotent operations where expected?

### 5. Help Text Quality
- Are `--help` descriptions clear and complete?
- Do examples exist where they'd help?
- Are required vs optional flags obvious?
- Is the command hierarchy discoverable?

## Severity Levels

- **P0** — blocks the workflow or causes data loss; new user cannot proceed
- **P1** — significant friction or confusion; workaround exists but isn't obvious
- **P2** — cosmetic or minor polish; noticeable but not blocking

## Behavior Rules

- **Non-destructive** — only create `dx-test-*` resources, always clean up
- **Stop on blockers** — if context setup fails, report immediately
- **Adapt** — if a command doesn't exist, skip it and note the gap
- **No login** — assume authenticated
- **Note friction in real time** — every unexpected prompt, confusing error, missing flag, or silent success is a finding; capture it immediately with raw output before moving on
- **No source diving** — do not read internal source code unless a specific bug demands it; test only via the CLI surface
- **Be thorough** — exercise every flag, every output mode, every edge case you can think of
- **Compare** — when evaluating consistency, compare every command group against each other
