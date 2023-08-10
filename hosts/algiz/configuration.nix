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

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # systemd services in order to keep soft-serve list up to date
  systemd = {
    timers.softServe = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # every day at 4:AM
        OnCalendar = "*-*-* 4:00:00";
      };
    };
    services.softServe = {
      wantedBy = [ "multi-user.target" ];
      description = "update soft serve git repos";
      serviceConfig = {
        type = "oneshot";
        ExecStart =
          let gitDir = "/home/daylin/git";
          in
          ''
            ${pkgs.python3.interpreter} "${gitDir}/soft/config/update-soft-serve-repos.py" && \
            ${pkgs.docker} compose --project-directory ${gitDir} restart
          '';
      };
    };
  };

  networking = {
    hostName = "algiz";

    # added to make using `pip install` work in docker build
    nameservers = [
      "8.8.8.8"
    ];
  };

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

