---
name: legible-code
description: Write code whose structure carries its own explanation instead of narrating it in comments. Use whenever writing or editing code in any language — before finalizing any Write or Edit to a source file. Treats the urge to explain a block in a comment as a signal to restructure it (extract, name, invert, simplify). Also invocable explicitly as /legible-code to audit comments in the current diff.
metadata:
  internal: true
---

# legible-code

A comment that explains *what* code does is a bug report against that code. Fix the code.

## The trigger

The moment you feel the urge to write an explanatory comment, stop. That urge is
the most reliable signal available that the code below it is unclear, doing too
much, or wrong. It is a design smell, not a documentation need.

Ask, in order:

1. Can a **name** carry this? → rename the variable/function/type.
2. Can a **boundary** carry this? → extract the block into a named function.
3. Can the **type system** carry this? → make the invalid state unrepresentable.
4. Can **structure** carry this? → early return, invert the condition, split the branch.
5. Only if all four fail: write the comment — and write it about *why*, never *what*.

## Comment smells → structural fix

**Narration.** Restates the code in English.

```ts
// loop through users and collect the active ones
const result = []
for (const u of users) { if (u.status === 1) result.push(u) }
```
→ `const activeUsers = users.filter(isActive)`

**Section dividers.** `// --- validation ---`, `// setup`, `// now do the write`.
These are function boundaries that were never drawn. Extract each section into a
named function; the divider becomes the call site.

**Magic-value glosses.** `if (retries > 3) // max allowed` → name the constant:
`if (retries > MAX_RETRIES)`.

**Condition glosses.** `// only paid, non-trial, non-expired accounts` above a
four-clause boolean → extract a predicate: `if (isBillable(account))`.

**Diff narration.** `// now uses the cache instead of hitting the DB`,
`// renamed from fetchUser`, `// added to handle the null case`. The reader of
this file has no idea what it used to be and does not care. This belongs in the
commit message. Delete it.

**Apology and hedge.** `// this is a bit hacky`, `// TODO: clean up`, `// for now`,
`// not sure if this is right`, `// assumes input is sorted`. Two outcomes only:
- Fix it now, and write no comment; or
- Leave it, and say the caveat **to the user in your response** — not in the source.

A hedge in a comment is a decision you declined to make, hidden where the user
will not read it. Surfacing it in chat is how the user gets to make the call.

**Signature restatement.** A doc block that re-lists the parameters and their
types with no added information. Either say something the signature cannot, or
say nothing.

**Defensive-code justification.** `// shouldn't happen, but just in case`. If it
cannot happen, delete the branch. If it can, handle it as a real case with a real
error. If you genuinely cannot tell, that is a question for the user.

## What legitimately survives

Comments carrying information that is **not derivable from the code**:

- **External constraint** — `// S3 eventual consistency: this read can lag the write by ~seconds`
- **Spec or protocol reference** — `// RFC 6265 §5.1.4: paths are matched by prefix, not segment`
- **Counterintuitive workaround** — the surprising-looking line, plus the upstream
  issue link or reproduction that forces it. Without the link it is folklore.
- **Rejected obvious alternative** — `// sequential on purpose: the API 429s above 2 rps`
- **Measured tradeoff** — `// map beats a set here; n is always < 8 (benchmarked)`
- **Invariant the types cannot express** — held lock, call ordering, unit of a number.
- **API doc comments** where the language or repo convention requires them
  (exported Go identifiers, published library surface, generated docs).

Test for each: does a competent reader who reads the code still not know this?
If they'd learn it from the code, cut it.

## Density matches the file

Read the surrounding code before writing. A file with no comments is a file whose
author chose that; adding a dense block to your five new lines makes your change
look bolted on. Match the local convention — in both directions.

## Before finalizing any edit

Reread each comment you wrote and answer: *what does the reader lose if I delete
this line?* If the answer is "nothing" — delete it. If the answer is "they would
not understand the code" — the code is the problem; go back to step 1.

## Don'ts

- **Don't delete comments you didn't write.** Existing comments may encode context
  you don't have. Rewriting a function invalidates its stale comment — update that.
  Unrelated comments are out of scope.
- **Don't strip required doc comments** to satisfy this skill. Linters and public
  API surfaces win.
- **Don't compensate by writing zero comments.** The goal is a high hit rate, not
  abstinence. One comment that explains a non-obvious constraint is worth more than
  a clean file that hides a landmine.
- **Don't over-extract.** A four-line function called from one place, named
  `handleTheThing`, is worse than the four lines inline. Extraction must produce a
  name that is genuinely more informative than its body.
