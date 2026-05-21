---
name: review-plan
description: Critique a markdown plan, spec, or design doc — grounded in the actual codebase it touches, not in isolation. Use when the user asks to "review this plan/spec/design" or invokes /review-plan with a path. Single-pass review that leaves comments in chat; does not edit the doc unless explicitly asked. Handles re-reviews by diffing against prior critique. NOT for reviewing code diffs or PRs.
---

# review-plan

Focused critique of a markdown plan/spec/design doc, grounded in the codebase it modifies. Output goes to chat. Do **not** edit the plan unless the user explicitly asks.

## Resolving the target

- `/review-plan <path>` — review that file.
- Bare `/review-plan` — find the most recently modified `*.md` under `docs/superpowers/specs/` from the repo root and review it. If the top two candidates were modified within ~10 minutes of each other, list them and ask which.
- Path missing or not markdown → ask, don't guess.

## Process

1. **Read the plan fully** before forming any opinion.
2. **Ground in the codebase.** For every concrete artifact the plan proposes — new error type, new helper, new file layout, new flag, new command structure — check whether the codebase already has it. Grep / Read on:
   - The package(s) the plan modifies
   - Existing error types, helpers, and command patterns the plan would parallel
   - Sibling files that establish conventions (file naming, file count, how similar features are organized today)
   The single highest-value finding is "you're proposing X, but `Y` already does this at `file:line`" — these are the ones a doc-only review misses.
3. **Cite concretely.** Plan claims → quote line numbers in the plan ("Line 180:"). Codebase claims → use `file:line` (e.g., `cli/pkg/cmd/login.go:87`). Never assert "X already exists" without a path.
4. **Detect re-review.** If the plan visibly changed since a prior review in this conversation, or the user says "I revised it / re-review it", switch to the re-review output shape below.

## Output shape — initial review

```
<One-line framing: overall direction and whether concerns are localized or structural.>

### 1. <Concern title>
<Prose. Show the alternative concretely — fenced code, or "use X at file:line".>

### 2. <Concern title>
...

---

### Summary

| # | Change | Severity |
|---|--------|----------|
| 1 | <one-line action> | **High** — <why it's high> |
| 2 | ... | Medium |
| 3 | ... | Low |

<Closing line: name what's genuinely strong, but don't sugar-coat. Hiding the truth only hurts the developer — if there's nothing strong, say so.>
```

Numbering in the table matches the in-body section numbers exactly.

**Severity:**
- **High** — wire contract, type safety, parallel-types-with-existing-code, or structural file layout. Append `— <rationale>` after the bold tag.
- **Medium** — code shape, clarity, dead-code or contradictions in the plan.
- **Low** — nits, polish, missing open questions, wording.

## Output shape — re-review

```
<One-line framing on whether the revision is materially better.>

### Resolved since last review

- **<original concern headline>** ✓ — <how it was resolved, with file:line if applicable>
- ...

### Remaining concerns (all minor / still open)

### 1. <title>
...

---

<Verdict — see below>
```

List every prior concern under "Resolved" with a checkmark, OR move it under "Remaining" with its current state. Don't silently drop items.

## Verdict

- **Initial review with substantive concerns:** no explicit verdict line — the High rows in the table carry the message.
- **Re-review where only minor items remain:** classify each remaining item as one of `must-fix` / `note` / `tradeoff` / `bikeshed`, then close with a single line: `Otherwise: ship it.` or `One more pass needed on #N.`

## Don'ts

- Don't edit the plan. Leave comments in chat. (If the user later says "apply your suggestions," that's a separate task.)
- Don't fan out to parallel reviewer agents. One reviewer with full codebase context beats three with partial views — and a plan rarely has enough surface area to justify the split.
- Don't critique the plan in isolation. Every "this is wrong / redundant / inconsistent" claim should pair with a `file:line` showing what the codebase does instead, or an explicit "I checked and found no precedent."
- Don't sugar-coat. Be transparent about what's good, but never inflate it to soften the criticism — hiding the truth only hurts the developer.
