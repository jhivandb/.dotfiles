
# Home Manager Configuration

This repository contains my personal [home-manager](https://github.com/nix-community/home-manager) configuration for managing dotfiles and user packages across systems.

## Configuration

- **Shell**: Fish with oh-my-posh (shrewd_minimal theme)
- **Terminal**: Ghostty with Catppuccin Mocha theme
- **Editor**: Zed (Catppuccin Mocha), Micro
- **Tools**: kubectl, helm, kind, gh, bat, zoxide

Managed config files live under [`home-manager/config/`](home-manager/config/) and are linked into
place with `mkOutOfStoreSymlink`, so edits made by the apps themselves land back in this repo.

## Applying

```bash
home-manager switch -f home-manager/home.nix
```

## Skills

Agent skills live in [`skills/`](skills/). Install the publicly-exposed ones into any project or globally with the [`skills`](https://github.com/vercel-labs/skills) CLI:

```bash
npx skills add jhivandb/.dotfiles        # into the current project (.claude/skills)
npx skills add jhivandb/.dotfiles -g     # globally (~/.claude/skills)
npx skills add jhivandb/.dotfiles -l     # list exposed skills without installing
```

Exposed skills:

- `am-ship` — git workflow and commit conventions for the agent-manager repo
- `review-plan` — critique a markdown plan, spec, or design doc grounded in the codebase it touches

Other skills in `skills/` are kept internal (`metadata.internal: true`) and are skipped by `npx skills add`. They're still active locally via the home-manager symlink.
