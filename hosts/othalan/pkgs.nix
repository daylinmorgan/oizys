{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [ (flake.pkg "utils") ]
    ++ (with pkgs; [
      zk
      quarto
      cachix
      graphviz
      # nix-du # failing to build suddenly? 
      # https://github.com/symphorien/nix-du/issues/23
      # maybe llvm related?
    ]);
}
