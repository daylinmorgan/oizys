{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.programs.hyprland;
in {
  config = mkIf cfg.enable {
    security.pam.services.swaylock = {};
    # programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.default;
    # Optional, hint electron apps to use wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      wlr-randr
      kanshi

      swaylock
      brightnessctl
      udiskie

      # notifications
      libnotify
      dunst

      # screenshots
      grimblast

      eww-wayland
      rofi-wayland
      hyprpaper

      catppuccin-cursors.mochaDark
      pavucontrol

      wl-clipboard
    ];

    nixpkgs.overlays = [
      inputs.hyprland-contrib.overlays.default
      inputs.nixpkgs-wayland.overlay
      inputs.hyprland.overlays.default
    ];
  };
}
