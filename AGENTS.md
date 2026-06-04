# Repo conventions

## Skills

When adding a skill to this repo, ask whether to expose it via `npx skills`.

- **Expose (public):** leave the `SKILL.md` frontmatter as-is.
- **Keep internal (default):** add `metadata.internal: true` to the `SKILL.md` frontmatter so `npx skills add` skips it.
