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

      # wallpapers
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
    ]);

  nixpkgs.overlays = [
    (flake.overlay "hyprland-contrib")
    # (overlayFrom "nixpkgs-wayland")
    # (overlayFrom "hyprland")
  ];

  # using the below to autostart Hyprland
  # broke my keybindings that were working before
  #
  # services.getty = {
  #   extraArgs = [ "--skip-login" ];
  #   loginOptions = "-p -- ${config.oizys.user}";
  # };

  # environment.etc =
  #   let
  #     activate-snippet = ''
  #       if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  #         exec Hyprland
  #       fi
  #     '';
  #   in
  #   {
  #     "bashrc.local".text = activate-snippet;
  #     "zshenv.local".text = activate-snippet;
  #   };
  #

}
