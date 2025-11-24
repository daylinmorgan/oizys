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
in

mkOizysModule config "niri" {

  programs.niri = enabled;
  systemd.user.services = {
    mako = niriService {
      serviceConfig = {
        ExecStart = ''${pkgs.mako}/bin/mako'';
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
        # current is a symlink
        ExecStart = ''${pkgs.swaybg}/bin/swaybg -m fill -i "%h/stuff/wallpapers/current"'';
        Restart = "on-failure";
      };
    };

    swayidle = niriService {
      path = with pkgs; [
        niri
        swaylock
        swayidle
      ];
      serviceConfig = {
        ExecStart = ''${pkgs.bash}/bin/bash -c "swayidle -w"'';
        Restart = "on-failure";
      };
    };

  };

  environment.systemPackages = [
    (flake.pkg "niriman")
  ]
  ++ (with pkgs; [
    xwayland-satellite
    wl-mirror
    wlr-randr

    kanshi

    libnotify
    mako

    brightnessctl
    udiskie

    wl-clipboard
    rofi
    pwvucontrol
    swaylock
    eww
    swww
  ]);

  services.getty = {
    extraArgs = [ "--skip-login" ];
    loginOptions = "-p -- ${config.oizys.user}";
  };
}
