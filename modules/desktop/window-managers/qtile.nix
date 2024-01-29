{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.services.xserver.windowManager.qtile;
in {
  config = mkIf cfg.enable {
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
  };
}
