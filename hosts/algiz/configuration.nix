{ inputs, lib, config, pkgs, ... }:
{
  # TODO: put in hardware-configuration.nix
  imports = [
    ./hardware-configuration.nix
  ];
  security.sudo.wheelNeedsPassword = false;
  users.defaultUserShell = pkgs.zsh;
  users.extraUsers = {
    daylin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      useDefaultShell = true;
      initialPassword = "nix";
    };
    git = {
      isNormalUser = true;
    };
  };

  services.resolved.enable = true;
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

  networking.hostName = "algiz"; 
  time.timeZone = "America/Chicago";
  programs.zsh.enable = true;
  virtualisation.docker.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    curl # for choosenim
  ];

  environment.systemPackages = with pkgs; [
    zsh

    tmux
    wget
    unzip
    less
    gnumake
    gcc
    gnupg

    curl

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

    python3
    micromamba

    nodejs
    go
    rustup
  ];


  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  users.mutableUsers = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

