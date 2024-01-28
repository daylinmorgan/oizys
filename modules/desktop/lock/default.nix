{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.services.xserver.windowManager.qtile;
  lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = with pkgs; [i3lock-color figlet procps];
        text = builtins.readFile ./lock.sh;
      };


in {
  config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        xss-lock
        lock
      ];

      systemd.services.i3lock = {
        wantedBy = ["sleep.target"];
        description = "Lock the screen using a custom lock script";
        before = ["suspend.target"];
        serviceConfig = {
          User = "daylin";
          Type = "forking";
          Environment = "DISPLAY=:0";
          ExecStart = "${lock}/bin/lock";
        };
      };

    };
  }
