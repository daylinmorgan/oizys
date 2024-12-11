{
  pkgs,
  self,
  enabled,
  ...
}:
{
  imports = with self.nixosModules; [ git ];
  programs.zsh = enabled;
  environment.systemPackages = with pkgs; [
    tmux
    unzip
    zip
    less
    gnumake
    gcc
    file

    wget
    curl
    htop
  ];
}
