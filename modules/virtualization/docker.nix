{
  pkgs,
  config,
  mkOizysModule,
  ...
}:
let
# TODO: polish this up
 win10vm = pkgs.stdenvNoCC.mkDerivation {
  name = "win10vm";
  unpackPhase = "true";
  buildPhase = "mkdir $out";
  version = "unstable";
  desktopItem = pkgs.makeDesktopItem {
    name = "win10vm";
    exec = "VBoxManage startvm win10";
    # icon = ""; # TODO: add windows icon
    desktopName = "Windows 10 VM";
  };
};
in 
mkOizysModule config "docker" {
  virtualisation.docker.enable = true;
  environment.systemPackages = (with pkgs; [ lazydocker]) ++ [ win10vm];
}
