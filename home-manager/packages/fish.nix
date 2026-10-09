{ config, lib, pkgs, ... }:

let
  # Static equivalent of `brew shellenv`, set as session env so fish, bash and
  # zsh all get it without spawning brew or stat'ing the prefix (on macOS,
  # stat'ing /home wakes automountd).
  brew =
    if pkgs.stdenv.isDarwin then
      { prefix = "/opt/homebrew"; repository = "/opt/homebrew"; }
    else
      { prefix = "/home/linuxbrew/.linuxbrew"; repository = "/home/linuxbrew/.linuxbrew/Homebrew"; };
in
{

  home.packages = with pkgs; [
  ];

  home.sessionVariables = {
    HOMEBREW_PREFIX = brew.prefix;
    HOMEBREW_CELLAR = "${brew.prefix}/Cellar";
    HOMEBREW_REPOSITORY = brew.repository;
    INFOPATH = "${brew.prefix}/share/info:\${INFOPATH:-}";
  };
  home.sessionPath = [ "${brew.prefix}/bin" "${brew.prefix}/sbin" ];

  programs = {
    fish = {
      enable = true;
      # No /etc/fish/conf.d nix hook exists here, so without this the profile
      # is never on PATH and tools called by name (zoxide hook, Claude's
      # status-line) fail.
      shellInit = ''
        set -l nix_profile_script ${config.home.profileDirectory}/etc/profile.d/nix.fish
        test -e $nix_profile_script; and source $nix_profile_script
      '';
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';

      plugins = [
        {
          name = "nvm";
          src = pkgs.fishPlugins.nvm.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "sdkman-for-fish";
          src = pkgs.fishPlugins.sdkman-for-fish.src;
        }
        {
          name = "fish-you-should-use";
          src = pkgs.fishPlugins.fish-you-should-use.src;
        }
        {
          name = "bass";
          src = pkgs.fishPlugins.bass.src;
        }
      ];
      functions = {
        b64d = "echo -n $argv | base64 -d";
      };
      shellAbbrs = {
        g = "git";
        gco = "git checkout";
        gs = "git status";
        k = "kubectl";
        kg = "kubectl get";
        kgp = "kubectl get pods";
        dcmp = "docker-compose";
      };
      shellAliases = {
        gcm = "git commit -m";
        op46 = "claude --model 'claude-opus-4-6[1m]'";
      };
    };
  };

}
