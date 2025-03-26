{
  pkgs,
  inputs,
  config,
  mkOizysModule,
  enabled,
  flake,
  ...
}:

let
  niriService =
    {
      serviceConfig,
      description ? "",
      path ? [ ],
    }:
    enabled
    // {
      inherit description serviceConfig path;
      wantedBy = [ "niri.service" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
    };
  eww = (flake.pkgs "nixpkgs-wayland").eww;
  mako = (flake.pkgs "nixpkgs-wayland").mako;
in
mkOizysModule config "niri" {
  nixpkgs.overlays = [
    inputs.nixpkgs-wayland.overlay
  ];

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

  systemd.user.services = {
    mako = niriService {
      serviceConfig = {
        ExecStart = ''${mako}/bin/mako'';
        Restart = "on-failure";
      };
    };

    udiskie = niriService {
      serviceConfig = {
        ExecStart = ''${pkgs.udiskie}/bin/udiskie'';
        Restart = "on-failure";
      };
    };

    kanshi = niriService {
      serviceConfig = {
        ExecStart = ''${pkgs.kanshi}/bin/kanshi'';
        Restart = "on-failure";
      };
    };

    # TODO: intregrate elsewhere or just go back to using swww?
    swaybg = niriService {
      description = "swaybg!";
      serviceConfig = {
        ExecStart = ''${pkgs.swaybg}/bin/swaybg -m fill -i "%h/stuff/wallpapers/mountain-temple/mountain-temple_00001_.png"'';
        Restart = "on-failure";
      };
    };
  };

  environment.systemPackages =
    [ (flake.pkg "niriman") ]
    ++ (with pkgs; [
      niri
      xwayland-satellite
      wl-mirror
      wlr-randr

      kanshi

      libnotify
      mako

      brightnessctl
      udiskie

      wl-clipboard
      rofi-wayland
      pwvucontrol
      catppuccin-cursors.mochaDark
      swaylock
      eww
      swww
    ]);

  services.getty = {
    extraArgs = [ "--skip-login" ];
    loginOptions = "-p -- ${config.oizys.user}";
  };
}
