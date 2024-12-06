{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [
      (flake.pkg "utils")
      (flake.pkg "ghostty")
      (flake.pkg "jj")
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
      # jujutsu
    ]);
}
