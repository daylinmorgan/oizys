{
  lib,
  self,
  ...
}: {
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

    gui

    languages

    # programs
    chrome
    vscode

    nix-ld
  ];

  options.oizys.desktop.enable = lib.mkEnableOption "is desktop";
}
