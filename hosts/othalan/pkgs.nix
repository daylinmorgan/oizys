{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [
      (flake.pkg "utils")
      (flake.pkg "ghostty")
    ]

    ++ (with pkgs; [

      distrobox
      zk
      quarto
      cachix
      graphviz
      typst
      charm-freeze
      attic-client
      jujutsu
    ]);
}
