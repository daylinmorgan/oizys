{
  lib,
  self,
  ...
}: let
  inherit (lib) mkEnableOption;
in {
  imports = with self.nixosModules; [
    users
    nix
    cli
    dev
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
}
