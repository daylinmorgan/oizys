{
  lib,
  self,
  hostName,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  imports = with self.nixosModules; [
    users
    runes
    nix

    essentials
    cli
    nvim
    vpn
    gpg

    lock
    qtile
    hyprland

    virtualbox
    docker

    gui
    fonts

    languages

    # programs
    chrome
    vscode

    nix-ld
    restic
  ];

  options.oizys.desktop.enable = mkEnableOption "is desktop";
  options.oizys.docker.enable = mkEnableOption "enable docker support";
  config = {
    networking.hostName = hostName;
    time.timeZone = "US/Central";
  };
}
