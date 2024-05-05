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
  programs.hyprland =
    enabled
    // {
      package = inputs.hyprland.packages.${pkgs.system}.default;
    };
  security.pam.services.swaylock = {};
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
    # some issue with dunst?
    # inputs.nixpkgs-wayland.overlay
    
    # when this was active I was forced to recompile VirtualBox myself, which would just fail to compile...
    # Must have been one of the other non-hyprland packages modified in the overlay
    # inputs.hyprland.overlays.default
  ];
}
