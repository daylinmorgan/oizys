{
  config,
  mkOizysModule,
  pkgs,
  ...
}:
let

  win10vm = pkgs.stdenvNoCC.mkDerivation rec {
    name = "win10vm";
    unpackPhase = "true";
    version = "unstable";
    windows10Logo = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/c/c7/Windows_logo_-_2012.png";
      hash = "sha256-uVNgGUo0NZN+mUmvMzyk0HKnhx64uqT4YWGSdeBz3T4=";
    };

    desktopItem = pkgs.makeDesktopItem {
      name = "win10vm";
      exec = "VBoxManage startvm win10";
      icon = "${windows10Logo}";
      desktopName = "Windows 10 VM";
    };
    installPhase = ''
      install -Dm0644 {${desktopItem},$out}/share/applications/win10vm.desktop
    '';
  };
in
mkOizysModule config "vbox" {
  virtualisation.virtualbox = {
    host.enable = true;
  };
  users.extraGroups.vboxusers.members = [ "daylin" ];
  environment.systemPackages = [ win10vm ];
}
