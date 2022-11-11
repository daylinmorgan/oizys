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

  # todo import from a different file
  nixpkgs.overlays = [
    (self: super:
      {
        wavebox = super.wavebox.overrideAttrs
          (old: {
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

        picom = super.picom.overrideAttrs (o: {
          src = pkgs.fetchFromGitHub {
            repo = "picom";
            owner = "ibhagwan";
            rev = "44b4970f70d6b23759a61a2b94d9bfb4351b41b1";
            sha256 = "0iff4bwpc00xbjad0m000midslgx12aihs33mdvfckr75r114ylh";
          };
        });
      })
  ];

  # networking.hostName = "nixos"; # Define your hostname.

  time.timeZone = "America/Chicago";

  programs.zsh.enable = true;

  # overwrite demo as default login
  services.xserver = {
    enable = true;
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
    dunst
    picom


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
