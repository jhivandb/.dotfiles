{ config, pkgs, ... }:
# Inspiration https://codeberg.org/justgivemeaname/.dotfiles/src/branch/main/home-manager/beard/home.nix
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jhivandb";
  home.homeDirectory = "/home/jhivandb";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  nixpkgs.config.allowUnfreePredicate = (pkg: true);
  home.packages = [
    pkgs.neovim
    pkgs.bat
    pkgs.helm
    pkgs.kubectx
    pkgs.gh
    pkgs.kind
    pkgs.kubectl
    pkgs.zoxide
    pkgs.babelfish
    pkgs.zed-editor
    pkgs.micro
    pkgs.nerd-fonts.fira-code
    pkgs.claude-code
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
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        # Homebrew setup
        if test -d /home/linuxbrew/.linuxbrew
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        end

        # Zoxide setup (if installed)
        if command -v zoxide > /dev/null
            zoxide init fish | source
        end
      '';

      shellAbbrs = {
        g = "git";
        gco = "git checkout";
        gs = "git status";
        k = "kubectl";
        kg = "kubectl get";
        kgp = "kubectl get pods";
      };
    };
    oh-my-posh = {
      enable = true;
      enableFishIntegration = true;
      useTheme = "amro";
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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jhivandb/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
}
