{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [ (flake.pkg "utils") ]
    ++ (with pkgs; [
      distrobox
      zk
      quarto
      cachix
      graphviz
      typst
      charm-freeze
    ]);
}
