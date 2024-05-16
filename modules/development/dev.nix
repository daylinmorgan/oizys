{ pkgs, self, ... }:
{
  imports = with self.nixosModules; [ git ];
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    tmux
    unzip
    zip
    less
    gnumake
    gcc

    jq

    wget
    curl
    htop
  ];
}
