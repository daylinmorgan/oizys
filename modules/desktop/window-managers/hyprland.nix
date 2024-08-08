{
  pkgs,
  config,
  mkOizysModule,
  enabled,
  flake,
  ...
}:
let
  activate-snippet = ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
      exec Hyprland
    fi
  '';
in

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

      # not even clear why I need to add this but ¯\_(ツ)_/¯
      kdePackages.qtwayland
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

  services.getty = {
    extraArgs = [ "--skip-login" ];
    loginOptions = "-p -- ${config.oizys.user}";
  };

  environment.etc = {
    "bashrc.local".text = activate-snippet;
    "zshenv.local".text = activate-snippet;
  };

  nixpkgs.overlays = [
    (flake.overlay "hyprland-contrib")
    # (overlayFrom "nixpkgs-wayland")
    # (overlayFrom "hyprland")
  ];
}
