{ pkgs, flake, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    (flake.pkg "neovim-nightly-overlay")
    # neovim

    # nixd
    tree-sitter
  ];
}
