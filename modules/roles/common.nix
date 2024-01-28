{inputs, ...}: {
  imports = with inputs.self.nixosModules; [
    users
    nix
    cli
    dev
    nvim
    vpn

    # langs
    python
    misc
    node
    tex
    nim
  ];
}
