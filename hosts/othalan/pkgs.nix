{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [
      (flake.pkg "utils")
      (flake.pkg "ghostty")
    ]

    ++ (with pkgs; [
      sops
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
