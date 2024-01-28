{inputs, lib, ...}: {
  imports = with inputs.self.nixosModules; [
    users
    nix
    cli
    dev
    nvim
    vpn

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

