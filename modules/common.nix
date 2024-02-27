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

    gui

    languages

    # programs
    vivaldi
    vscode
  ];

  options.oizys.desktop.enable = lib.mkEnableOption "is desktop";
}
