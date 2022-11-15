{ lib, config, pkgs, ... }:

{
  imports =
    [
      <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
    ];

  nix.package = pkgs.nixUnstable;
  nixpkgs.config.allowUnfree = true;
  nix.extraOptions = ''
    	experimental-features = nix-command flakes
    	'';
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # todo import from a different file

  networking.hostName = "nixos-vm"; # Define your hostname.

  time.timeZone = "America/Chicago";

  programs.zsh.enable = true;

  # overwrite demo as default login
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    displayManager.sddm.enable = lib.mkForce false;

    displayManager.autoLogin.enable = lib.mkForce false;
    windowManager.qtile.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.daylin = {
      shell = pkgs.zsh;
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      packages = with pkgs; [
      ];
    };
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    noto-fonts-extra
    (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; })
  ];

  # for compatibility add zsh to list of /etc/shells
  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [

    fuse
    zsh

    wget
    less
    gnumake
    gcc

    git

    vim
    neovim
    starship
    chezmoi
    delta
    gh

    nixpkgs-fmt

    xdotool
    wezterm
    eww
    rofi
    dunst
    feh
    picom


    (python3.withPackages (p: with  p;
    [ pynvim ]))

    # firefox
    wavebox


    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    })


    go
    rustup

  ];


  environment.etc = {
    issue.source = ./etc/issue;
  };

  environment.variables = {
    NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
      stdenv.cc.cc
      openssl

      zlib # for delta
      fuse # for libfuse/Neovim Appimage
    ];
    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };

}
