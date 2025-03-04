{
  pkgs,
  config,
  mkOizysModule,
  flake,
  ...
}:

mkOizysModule config "niri" {

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
