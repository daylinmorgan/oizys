{ pkgs, self, ... }:
{
  imports = with self.nixosModules; [ git ];
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    tmux
    unzip
    less
    gnumake
    gcc

    jq

    wget
    curl
    htop
  ];
}
