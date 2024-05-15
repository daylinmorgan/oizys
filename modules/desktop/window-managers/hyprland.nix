{
  inputs,
  pkgs,
  config,
  mkOizysModule,
  enabled,
  ...
}:
# let
#   lock = pkgs.writeShellApplication {
#     name = "lock";
#     runtimeInputs = with pkgs; [swaylock];
#     text = ''
#       swaylock -c 1e1e2e
#     '';
#   };
mkOizysModule config "hyprland" {
  programs.hyprland = enabled // {
    package = inputs.hyprland.packages.${pkgs.system}.default;
  };
  security.pam.services.swaylock = { };
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    wlr-randr
    kanshi

    brightnessctl
    udiskie
    eww

    # notifications
    libnotify
    dunst

    # utils
    grimblast
    ksnip
    wl-clipboard
    rofi-wayland
    pavucontrol

    catppuccin-cursors.mochaDark

    #hypr ecosystem
    hyprlock
    hypridle

    swww
  ];

  nixpkgs.overlays = [
    inputs.hyprland-contrib.overlays.default
    inputs.nixpkgs-wayland.overlay

    # inputs.hyprland.overlays.default
  ];
}
