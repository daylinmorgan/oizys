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

  nixpkgs.overlays = [
    (self: super: /* overlay goes here */

      {
        wavebox = super.wavebox.overrideAttrs (old: {
          version = "10.107.10";
        });
      }


    )
  ];



  # networking.hostName = "nixos"; # Define your hostname.

  # time.timeZone = "Europe/Amsterdam";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # for compatibility add zsh to list of /etc/shells
  environment.shells = with pkgs; [ zsh ];



  # overrwite default login
  services.xserver.displayManager.autoLogin.enable = lib.mkForce false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.daylin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
    ];
  };

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
    (python3.withPackages (p: with  p;
    [ pynvim ]))
  ];


  fonts.fonts = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    last-resort
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
