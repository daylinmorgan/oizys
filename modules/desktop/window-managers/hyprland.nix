{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.programs.hyprland;

  lock = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = with pkgs; [swaylock];
    text = ''
      swaylock -c 1e1e2e
    '';
  };
in {
  config = mkIf cfg.enable {
    systemd.services.screen-locker = {
      wantedBy = ["sleep.target"];
      description = "Lock the screen using a custom lock script";
      before = ["suspend.target"];
      serviceConfig = {
        User = "daylin";
        Type = "forking";
        Environment = "DISPLAY=:0";
        ExecStart = "${lock}/bin/lock";
      };
    };
    security.pam.services.swaylock = {};
    # programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.default;
    # Optional, hint electron apps to use wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      wlr-randr
      kanshi

      lock
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
