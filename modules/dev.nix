{
  inputs,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    git
  ];
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

    comma
  ];
}
