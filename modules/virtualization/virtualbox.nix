{ config, mkOizysModule, pkgs,... }:
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
mkOizysModule config "vbox" {
  virtualisation.virtualbox = {
    host.enable = true;
  };
  users.extraGroups.vboxusers.members = [ "daylin" ];
  environment.systemPackages = [ win10vm ];
}
