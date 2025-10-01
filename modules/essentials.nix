{
  pkgs,
  self,
  flake,
  enabled,
  ...
}:
{
  imports = with self.nixosModules; [
    git
    nix
  ];
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

    sops

    (flake.pkg "self")
  ];

}
