# Inspiration https://codeberg.org/justgivemeaname/.dotfiles/src/branch/main/home-manager/beard/home.nix
# https://nix-community.github.io/home-manager/options.xhtml

{ config, pkgs, ... }:
let
  # Set to true to install GUI applications
  installGuiApps = false;
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
    pkgs.claude-code
    pkgs.nil
    pkgs.go
    pkgs.podman
    pkgs.colima
    pkgs.mkcert
    pkgs.protobuf
    pkgs.fd
    pkgs.fzf
    pkgs.jq
    pkgs.yq
    pkgs.xh
    pkgs.tree-sitter
  ] ++ pkgs.lib.optionals installGuiApps [
    # GUI Applications
    pkgs.firefox
    pkgs.zed-editor
    pkgs.vscode
    pkgs.discord
    pkgs.spotify
    pkgs.dbeaver-bin
  ] ++ [
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
    home-manager =  {
      enable = true;
    };
    bash = {
      initExtra = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
    oh-my-posh = {
      enable = true;
      enableFishIntegration = true;
      configFile = ./shrewd_minimal.omp.json;
    };
    kitty = {
      enable = true;
      themeFile = "Catppuccin-Mocha";
      shellIntegration.enableFishIntegration = true;
    };
    git = {
      enable =  true;
      settings = {
        user = {
          name = "Jhivan de Benoit";
          email = "jhivanb@gmail.com";
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
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };
  home.sessionVariables = {
    # EDITOR = "emacs";
    HOME_MANAGER_CONFIG = "${config.home.homeDirectory}/.dotfiles/home-manager/home.nix";
  };

  imports = [
    packages/fish.nix
  ];
}
