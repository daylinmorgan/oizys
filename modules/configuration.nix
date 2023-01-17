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

  networking.hostName = "nixos-vm"; # Define your hostname.

  time.timeZone = "America/Chicago";

  programs.zsh.enable = true;

  programs.nix-ld.enable = true;

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
    gtk3

    gnome.adwaita-icon-theme
    gnome.gnome-settings-daemon
    catppuccin-gtk


    # (python3.withPackages (p: with  p;
    # [ pynvim ]))

    # firefox
    wavebox

    pciutils
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
      commandLineArgs = "--force-dark-mode";
    })

    vscode.fhs

    go
    rustup

  ];

}
