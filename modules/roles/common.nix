{inputs, ...}: {
  imports = with inputs.self.nixosModules; [
    nix
    cli
    dev
    nvim

    # langs
    python
  ];
}
