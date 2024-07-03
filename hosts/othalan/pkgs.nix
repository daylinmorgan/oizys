{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    zk
    quarto
    cachix
    graphviz
    nix-du
  ];
}
