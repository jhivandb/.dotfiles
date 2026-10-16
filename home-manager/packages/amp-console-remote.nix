{ pkgs, ... }:

{
  home.packages = [
    # ssh, lsof, curl and pnpm come from the host so ~/.ssh config and the project's node apply.
    (pkgs.writeShellApplication {
      name = "amp-console-remote";
      runtimeInputs = [ pkgs.gettext ];
      text = builtins.readFile ./amp-console-remote/amp-console-remote.sh;
    })
  ];
}
