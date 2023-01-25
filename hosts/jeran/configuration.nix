{ inputs, lib, config, pkgs, ... }:
{
  # TODO: put in hardware-configuration.nix
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
  ];
  security.sudo.wheelNeedsPassword = false;
  users.defaultUserShell = pkgs.zsh;
  users.extraUsers = {
    daylin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      useDefaultShell = true;
    };
    git = {
      isNormalUser = true;
    };
  };

  services.resolved.enable = true;
  system.stateVersion = "22.11";
  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.cron = {
    enable = true;
    systemCronJobs = [
      # update repos
      "0 * * * * make -C /home/daylin/git soft-repos"
      # update container so home page is semi-accurate
      "0 2 * * * make -C /home/daylin/git update-soft-serve"
    ];
  };
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
    less
    gnumake
    gcc

    git

    vim
    neovim

    starship
    atuin
    chezmoi
    bat
    fzf
    delta
    ripgrep
    lsd

    gh
    lazygit

    nixpkgs-fmt
    lazydocker

    nodejs
    go
    rustup
  ];
}
