{ config, lib, pkgs, ... }:

let
  # Verbatim `brew shellenv` output. Spawning brew costs ~18ms per interactive
  # shell and its output is fixed per prefix, so it is pinned here instead.
  # Regenerate after a Homebrew upgrade with:
  #   env -i HOME=$HOME PATH=/usr/bin:/bin <prefix>/bin/brew shellenv fish
  brewShellenv = { prefix, repository }: ''
    if test -d ${prefix}
        set --global --export HOMEBREW_PREFIX "${prefix}"
        set --global --export HOMEBREW_CELLAR "${prefix}/Cellar"
        set --global --export HOMEBREW_REPOSITORY "${repository}"
        fish_add_path --global --move --path "${prefix}/bin" "${prefix}/sbin"
        if test -n "$MANPATH[1]"
            set --global --export MANPATH "" $MANPATH
        end
        if not set --query INFOPATH
            set INFOPATH ""
        end
        if not contains "${prefix}/share/info" $INFOPATH
            set --global --export INFOPATH "${prefix}/share/info" $INFOPATH
        end
    end
  '';
in
{

  home.packages = with pkgs; [
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      ''
      # Guarded per platform: on macOS, stat'ing /home wakes automountd (~20ms/shell).
      + lib.optionalString pkgs.stdenv.isLinux (brewShellenv {
        prefix = "/home/linuxbrew/.linuxbrew";
        repository = "/home/linuxbrew/.linuxbrew/Homebrew";
      })
      + lib.optionalString pkgs.stdenv.isDarwin (brewShellenv {
        prefix = "/opt/homebrew";
        repository = "/opt/homebrew";
      });

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
          name = "done";
          src = pkgs.fishPlugins.done.src;
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
