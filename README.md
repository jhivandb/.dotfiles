
# Home Manager Configuration

This repository contains my personal [home-manager](https://github.com/nix-community/home-manager) configuration for managing dotfiles and user packages across systems.

## Configuration

- **Shell**: Fish with oh-my-posh (amro theme)
- **Terminal**: Kitty with Catppuccin Mocha theme
- **Editor**: Neovim, Zed, Micro
- **Tools**: kubectl, helm, kind, gh, bat, zoxide

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
