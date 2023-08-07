{ inputs, lib, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    	experimental-features = nix-command flakes
    	'';

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

  # fail2ban config based on:
  # https://www.linode.com/docs/guides/how-to-use-fail2ban-for-ssh-brute-force-protection/
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
    jails =
      {
        sshd = ''
          port = ssh
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 3
          findtime = 300
          bantime = 3600
        '';
      };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # TODO: convert this to a systemd service/timer
  # services.cron = {
  #   enable = true;
  #   systemCronJobs = [
  #     # update repos
  #     "0 * * * * make -C /home/daylin/git soft-repos"
  #     # update container so home page is semi-accurate
  #     "0 2 * * * make -C /home/daylin/git update-soft-serve"
  #   ];
  # };
  #
  networking.hostName = "algiz";

  # added to make using `pip install` work in docker build
  networking.nameservers = [
    "8.8.8.8"
  ];

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

    (python3.withPackages (ps: with ps; [ pip ]))
    micromamba

    nodejs
    go
    rustup
  ];


  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # allow tcp connections for git.dayl.in (gitea)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  users.mutableUsers = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

