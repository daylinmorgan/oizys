{
  inputs,
  pkgs,
  config,
  mkOizysModule,
  enabled,
  pkgFrom,
  pkgsFrom,
  overlayFrom,
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

      #hypr ecosystem
      hyprlock
      hypridle

      swww

      catppuccin-cursors.mochaDark
    ])
    ++ [ (pkgFrom "hyprman") ]

    # swww-git is broken
    ++ (with (pkgsFrom "nixpkgs-wayland"); [
      mako
      eww
      wlr-randr
      # swww
      #
      # dunst
    ]);

  nixpkgs.overlays = [
    (overlayFrom "hyprland-contrib")
    # (overlayFrom "nixpkgs-wayland")
    # (overlayFrom "hyprland")
  ];
}
