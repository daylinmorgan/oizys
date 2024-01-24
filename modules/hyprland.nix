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
    programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.default;
    # Optional, hint electron apps to use wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    environment.systemPackages = with pkgs; [
      swaylock
      brightnessctl

      # notifications
      libnotify
      dunst

      # screenshots
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      grim
      slurp

      eww-wayland
      rofi-wayland
      hyprpaper

      catppuccin-cursors.mochaDark
      pavucontrol
    ];
    nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];
  };
}
