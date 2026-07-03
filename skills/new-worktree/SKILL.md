---
name: new-worktree
description: Create a git worktree for starting a new task, branched off the latest upstream/main (or origin/main when no upstream remote exists). Use when the user asks to make/create a worktree, start work in a worktree, or begin a task that needs an isolated checkout.
---

# New Worktree

Create an up-to-date worktree for a new task.

## Steps

1. **Pick the base remote** — prefer `upstream`, fall back to `origin`:

   ```bash
   git remote | grep -qx upstream && remote=upstream || remote=origin
   ```

2. **Fetch the latest changes** (never skip this):

   ```bash
   git fetch $remote
   ```

3. **Resolve the default branch** — use `main`; if `$remote/main` doesn't exist, use the remote HEAD:

   ```bash
   git rev-parse --verify -q $remote/main >/dev/null && base=main \
     || base=$(git rev-parse --abbrev-ref $remote/HEAD | cut -d/ -f2)
   ```

4. **Create the worktree** with a new branch named after the task (kebab-case, unless the user gave a name), as a sibling of the repo:

   ```bash
   git worktree add ../<repo-name>-worktrees/<branch> -b <branch> $remote/$base
   ```

5. **Continue the task inside the worktree** and report its path to the user.

## Notes

- Never base the branch on the local checkout — always on the freshly fetched `$remote/$base`.
- If the branch already exists, ask whether to reuse it (`git worktree add <path> <branch>`) or pick a new name.
