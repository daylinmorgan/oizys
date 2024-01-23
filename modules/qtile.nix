{
  input,
  pkgs,
  ...
}: {
  imports = [
    ./lock
  ];

  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["FiraCode"];})
  ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    desktopManager.plasma5.enable = true;
    windowManager.qtile.enable = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl

    picom
    # xorg utils
    xdotool
    xclip

    # xrandr friends
    autorandr
    arandr

    # notifications
    libnotify
    dunst

    # qtile & friends
    # qtile
    eww
    feh
    rofi

    flameshot
    catppuccin-cursors.mochaDark
    pavucontrol
  ];
}
