{inputs, ...}: {
  imports = with inputs.self.nixosModules; [
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
