{ config, pkgs, ... }:

{

  home.packages = with pkgs; [
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        # Homebrew setup
        if test -d /home/linuxbrew/.linuxbrew
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        end
        if test -d /opt/homebrew
            eval "$(/opt/homebrew/bin/brew shellenv)"
        end

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
        zed = "zeditor";
        gcm = "git commit -m";
      };
    };
  };

}
