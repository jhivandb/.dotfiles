{ pkgs, ... }:

{
  home.packages = [
    (pkgs.buildGoModule {
      pname = "status-line";
      version = "0.1.0";
      src = ./status-line;
      vendorHash = null;
      doCheck = false;
    })
  ];
}
