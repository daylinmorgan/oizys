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
    vscode

    # langs
    python
    misc
    node
    tex
    nim
  ];

  options.desktop.enable = lib.mkEnableOption "is desktop";
}
