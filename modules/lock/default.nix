{
  input,
  pkgs,
  ...
}: let
  lock = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = with pkgs; [i3lock-color figlet procps];
    text = builtins.readFile ./lock.sh;
  };
in {
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

  # services.logind.extraConfig = ''
  #   IdleAction=suspend
  #   IdleActionSec=1800
  # '';
}
