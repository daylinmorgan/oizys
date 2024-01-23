{
  input,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    vim
    neovim

    nixd
    tree-sitter
  ];
}
