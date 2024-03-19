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

    # gui
    fonts

    lock
    qtile
    hyprland

    virtualbox
    docker

    gui

    languages

    # programs
    chrome
    vscode

    nix-ld
  ];

  options.oizys.desktop.enable = mkEnableOption "is desktop";
}
