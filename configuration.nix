{ lib, config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
    ];

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    	experimental-features = nix-command flakes
    	'';

  #  programs.nix-ld.enable = true;

  # networking.hostName = "nixos"; # Define your hostname.

  # time.timeZone = "Europe/Amsterdam";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # for compatibility add zsh to list of /etc/shells
  environment.shells = with pkgs; [ zsh ];


  # xstuffs
  services.xserver.enable = true;
  services.xserver.autorun = false;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.windowManager.qtile.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.daylin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    fuse
    zsh

    wget
    gnumake
    gcc

    git

    vim
    neovim
    starship
    gh

    nixpkgs-fmt

 #   xdotool
    wezterm
 #   eww
 #   rofi
 #   picom
 #   dunst

    firefox
    (python3.withPackages (p: with  p; [ pynvim ]))
  ];


  fonts.fonts = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];


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
