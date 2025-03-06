{
  pkgs,
  config,
  mkOizysModule,
  enabled,
  flake,
  ...
}:

let
  niriService =
    {
      description,
      serviceConfig,
    }:
    enabled
    // {
      inherit description serviceConfig;
      wantedBy = [ "niri.service" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
    };

in
mkOizysModule config "niri" {

  # systemd.user.services."sway" = enabled // {
  #
  #   wantedBy = [
  #     "niri.service"
  #   ];
  #
  #   partOf = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   requisite = [ "graphical-session.target" ];
  #   description = "swaybg!";
  #
  #   serviceConfig = {
  #     ExecStart = ''${pkgs.swaybg}/bin/swaybg -m fill -i "%h/stuff/wallpapers/mountain-temple/mountain-temple_00001_.png"'';
  #     Restart = "on-failure";
  #   };
  # };

  systemd.user.services."sway" = niriService {
    description = "swaybg!";
    serviceConfig = {
      ExecStart = ''${pkgs.swaybg}/bin/swaybg -m fill -i "%h/stuff/wallpapers/mountain-temple/mountain-temple_00001_.png"'';
      Restart = "on-failure";
    };
  };


  environment.systemPackages =
    (with pkgs; [
      niri

      wl-mirror
      kanshi

      brightnessctl
      udiskie

      libnotify

      wl-clipboard

      rofi-wayland

      pwvucontrol

      catppuccin-cursors.mochaDark

      swaylock
    ])

    ++ (with (flake.pkgs "nixpkgs-wayland"); [
      mako
      eww
      wlr-randr
      swww
    ]);

  services.getty = {
    extraArgs = [ "--skip-login" ];
    loginOptions = "-p -- ${config.oizys.user}";
  };
}
