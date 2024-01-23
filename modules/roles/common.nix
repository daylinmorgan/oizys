{inputs, ...}: {
  imports = with inputs.self.nixosModules; [
    nix
    cli
    dev
    nvim

    # langs
    python
    misc
    node
    tex
    nim
  ];
}
