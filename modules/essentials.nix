{
  pkgs,
  self,
  enabled,
  ...
}:
{
  imports = with self.nixosModules; [ git ];
  programs.zsh = enabled;
  programs.fish = enabled;
  environment.systemPackages = with pkgs; [
    tmux
    unzip
    zip
    less
    gnumake
    gcc
    file

    jq

    wget
    curl
    htop
  ];
}
