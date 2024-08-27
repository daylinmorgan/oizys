{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [ (flake.pkg "utils") ]
    ++ (with pkgs; [
      zk
      quarto
      cachix
      graphviz
      typst
    ]);
}
