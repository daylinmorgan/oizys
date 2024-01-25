{
  inputs,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    lock
  ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
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
