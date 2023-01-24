{ lib, config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
  ];
  security.sudo.wheelNeedsPassword = false;

 users.defaultUserShell = pkgs.zsh;
users.extraUsers.daylin = {
isNormalUser = true;
extraGroups = ["wheel" "docker"];
useDefaultShell = true;
};
  services.openssh.passwordAuthentication = true;
	
  system.stateVersion = "22.11";
  nixpkgs.config.allowUnfree = true;

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    	experimental-features = nix-command flakes
    	'';
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "jeran"; # Define your hostname.
  time.timeZone = "America/Chicago";
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;
 
  environment.systemPackages = with pkgs; [
    zsh

    tmux
    wget
    unzip
    htop
    less
    gnumake
    gcc

    git

    vim
    neovim

    starship
    atuin
    # sheldon
    chezmoi
   
    fzf
    delta
    ripgrep
	lsd

    gh
    lazygit

    nixpkgs-fmt

	nodejs
    go
    rustup
  ];
}
