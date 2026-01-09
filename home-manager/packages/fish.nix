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
  };

}
