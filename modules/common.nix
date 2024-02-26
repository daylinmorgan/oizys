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

    # langs
    python
    misc
    node
    tex
    nim

    # programs
    vivaldi
    vscode
  ];

  options.desktop.enable = lib.mkEnableOption "is desktop";
}
