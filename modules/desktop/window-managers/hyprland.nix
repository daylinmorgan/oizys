{
  inputs,
  pkgs,
  config,
  mkOizysModule,
  enabled,
  ...
}:

mkOizysModule config "hyprland" {
  programs.hyprland = enabled;
  security.pam.services.swaylock = { };
  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages =
    (with pkgs; [
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
      pavucontrol

      # catppuccin-cursors.mochaDark

      #hypr ecosystem
      hyprlock
      hypridle

      swww
    ])
    ++ [ inputs.hyprman.packages.${pkgs.system}.default ]

    # swww-git isbroken
    ++ (with inputs.nixpkgs-wayland.packages.${pkgs.system}; [
      mako
      eww
      wlr-randr
      # swww
      #
      # dunst
    ]);

  nixpkgs.overlays = [
    inputs.hyprland-contrib.overlays.default
    # inputs.nixpkgs-wayland.overlay
    # inputs.hyprland.overlays.default
  ];
}
