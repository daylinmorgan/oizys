{
  pkgs,
  config,
  mkOizysModule,
  enabled,
  flake,
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
    ++ [ (flake.pkg "hyprman") ]

    # swww-git is broken
    ++ (with (flake.pkgs "nixpkgs-wayland"); [
      mako
      eww
      wlr-randr
      # swww
      #
      # dunst
    ]);

  nixpkgs.overlays = [
    (flake.overlay "hyprland-contrib")
    # (overlayFrom "nixpkgs-wayland")
    # (overlayFrom "hyprland")
  ];
}
