{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkOizysModule enabled;
  lock = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = with pkgs; [swaylock];
    text = ''
      swaylock -c 1e1e2e
    '';
  };
in
  mkOizysModule config "hyprland" {
    programs.hyprland = enabled;
    security.pam.services.swaylock = {};
    # Optional, hint electron apps to use wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      swayidle
      wlr-randr
      kanshi

      lock
      brightnessctl
      udiskie
      eww

      # notifications
      libnotify
      dunst

      # utils
      grimblast
      wl-clipboard
      rofi-wayland
      pavucontrol

      catppuccin-cursors.mochaDark
      hyprpaper
      swww
    ];

    nixpkgs.overlays = [
      inputs.hyprland-contrib.overlays.default
      inputs.nixpkgs-wayland.overlay
      inputs.hyprland.overlays.default
    ];
  }
