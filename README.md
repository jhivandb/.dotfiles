
# Home Manager Configuration

This repository contains my personal [home-manager](https://github.com/nix-community/home-manager) configuration for managing dotfiles and user packages across systems.

## Configuration

- **Shell**: Fish with oh-my-posh (amro theme)
- **Terminal**: Kitty with Catppuccin Mocha theme
- **Editor**: Zed, Micro
- **Tools**: kubectl, helm, kind, gh, bat, zoxide

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

## Testing with Docker

A Docker container is provided to test the configuration in an isolated Ubuntu environment with Nix and home-manager pre-installed.

### Usage

Start the container and enter the Fish shell:

```bash
docker-compose up -d
docker-compose exec home-manager-test fish
```

Inside the container, apply the configuration:

```bash
home-manager switch
```

The `home.nix` file is mounted read-only into the container, so any changes you make locally can be tested immediately.

### Cleanup

Stop and remove the container:

```bash
docker-compose down
```
