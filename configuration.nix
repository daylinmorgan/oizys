{ lib, config, pkgs, ... }:

{
  imports =
    [
      <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
    ];

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    	experimental-features = nix-command flakes
    	'';
  # todo import from a different file
  nixpkgs.overlays = [
    (self: super:
      {
        wavebox = super.wavebox.overrideAttrs (old: {
          version = "10.107.10";
          src = super.fetchurl {
            url = "https://download.wavebox.app/stable/linux/tar/Wavebox_10.107.10-2.tar.gz";
            sha256 = "sha256-cbcAmnq9rJlQy6Y+06G647R72HWcK97KgSsYgusSB58=";
          };
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
            qt5.wrapQtAppsHook
          ];
          buildInputs = with pkgs.xorg; [
            libXdmcp
            libXScrnSaver
            libXtst
            libXdamage
          ] ++
          (with pkgs; [
            alsa-lib
            gtk3
            nss
            mesa
          ]);
          postFixup = ''
            # make xdg-open overrideable at runtime
            makeWrapper $out/opt/wavebox/wavebox $out/bin/wavebox \
              --suffix PATH : ${super.xdg-utils}/bin
          '';
        });
      }


    )
  ];

  # networking.hostName = "nixos"; # Define your hostname.

  time.timeZone = "America/Chicago";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # for compatibility add zsh to list of /etc/shells
  environment.shells = with pkgs; [ zsh ];

  # overwrite demo as default login
  services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
  services.xserver.windowManager.qtile.enable = true;

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

    xdotool
    wezterm
    eww
    rofi
    picom
    dunst


    (python3.withPackages (p: with  p;
    [ pynvim ]))

    firefox
    wavebox


    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    })


    go
    rustup

  ];


  fonts.fonts = with pkgs; [
    font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    dejavu_fonts
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
