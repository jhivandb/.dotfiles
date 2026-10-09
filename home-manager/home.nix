# Inspiration https://codeberg.org/justgivemeaname/.dotfiles/src/branch/main/home-manager/beard/home.nix
# https://nix-community.github.io/home-manager/options.xhtml

{ config, pkgs, ... }:

let
  # Fish gets the same environment from packages/fish.nix and its plugins.
  posixShellEnv = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    if [ -z "''${NIX_PROFILES-}" ] && [ -e "${config.home.profileDirectory}/etc/profile.d/nix.sh" ]; then
      . "${config.home.profileDirectory}/etc/profile.d/nix.sh"
    fi
    export SDKMAN_DIR="$HOME/.sdkman"
    [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
  '';
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.stateVersion = "25.11"; # Please read the comment before changing.

  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  home.packages = [
    pkgs.bat
    pkgs.kubernetes-helm
    pkgs.kubectx
    pkgs.gh
    pkgs.kind
    pkgs.kubectl
    pkgs.zoxide
    pkgs.babelfish
    pkgs.micro
    pkgs.nerd-fonts.fira-code
    pkgs.nil
    pkgs.podman
    pkgs.colima
    pkgs.mkcert
    pkgs.fd
    pkgs.fzf
    pkgs.jq
    pkgs.yq
    pkgs.xh
    pkgs.tree-sitter
    pkgs.nixd
    pkgs.jdk
    # The nixpkgs channel only has 1.26rc1.
    (import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz") { }).go_1_26
  ]
  ++ [

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  programs = {
    # Let Home Manager install and manage itself.
    home-manager = {
      enable = true;
    };
    bash = {
      enable = true;
      # bashrcExtra runs before the interactive-only guard, so non-interactive
      # shells (Claude's Bash tool, scripts) get the environment too.
      bashrcExtra = posixShellEnv;
    };
    zsh = {
      enable = true;
      envExtra = posixShellEnv;
    };
    oh-my-posh = {
      enable = true;
      enableFishIntegration = true;
      configFile = ./shrewd_minimal.omp.json;
    };
    git = {
      enable = true;
      ignores = [
        "**/.claude/settings.local.json"
        "**/.claude/permissions.log"
      ];
      settings = {
        user = {
          name = "Jhivan de Benoit";
          email = "jhivanb@gmail.com";
        };
        signing = {
          key = "A9B895CB62225828C0F5FA486A65CE0F3CBDA54A";
          signByDefault = true;
        };
        extraConfig = {
          gpg.program = "gpg"; # or the full path from `which gpg`
        };
      };
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home-manager/claude/settings.json";
    ".claude/hooks".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home-manager/claude/hooks";
    ".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/skills";
    ".agents/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/skills";
    ".config/ghostty/config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home-manager/config/ghostty/config";
    };
    ".config/zed/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home-manager/config/zed/settings.json";
    };
  };
  home.sessionVariables = {
    # EDITOR = "emacs";
    HOME_MANAGER_CONFIG = "${config.home.homeDirectory}/.dotfiles/home-manager/home.nix";
  };

  imports = [
    packages/fish.nix
    packages/status-line.nix
  ];
}
