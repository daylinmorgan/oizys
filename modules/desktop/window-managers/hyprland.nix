{
  inputs,
  pkgs,
  config,
  lib,
  # mkOizysModule,
  enabled,
  flake,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.oizys.hyprland;
in
{
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  options.oizys.hyprland.enable = mkEnableOption "hyprland";

  config = mkIf cfg.enable {
    programs.hyprland = enabled;

    # security.pam.services.swaylock = { };

    # Optional, hint electron apps to use wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages =
      (with pkgs; [
        wl-mirror
        wlr-randr
        kanshi

        brightnessctl
        udiskie
        eww

        # notifications
        libnotify
        mako

        # utils
        grimblast
        ksnip
        wl-clipboard
        rofi-wayland
        pwvucontrol

        #hypr ecosystem
        hyprlock
        hypridle

        catppuccin-cursors.mochaDark

        # not even clear why I need to add this but ¯\_(ツ)_/¯
        # kdePackages.qtwayland
      ])
      ++ [
        (flake.pkg "hyprman")
      ]

      # swww-git is broken
      ++ (with (flake.pkgs "nixpkgs-wayland"); [
        mako
        eww
        wlr-randr
        swww
      ]);

    nixpkgs.overlays = [
      (flake.overlay "hyprland-contrib")
      # (overlayFrom "nixpkgs-wayland")
      # (overlayFrom "hyprland")
    ];

    services.getty = {
      extraArgs = [ "--skip-login" ];
      loginOptions = "-p -- ${config.oizys.user}";
    };
  };
}
