{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [
      (flake.pkg "utils")
      (flake.pkg "ghostty")
    ]
    ++ (with pkgs; [
      sops
      attic-client

      distrobox

      # cachix
      zk

      graphviz
      charm-freeze

      quarto

      calibre
    ]);
}
