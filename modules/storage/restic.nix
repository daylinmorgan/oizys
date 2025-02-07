{
  config,
  pkgs,
  mkOizysModule,
  flake,
  ...
}:
mkOizysModule config "backups" {
  # environment.systemPackages = with pkgs; [ rclone ];
  environment.systemPackages = [ (flake.pkgs "self").rclone ];

  services.restic.backups.gdrive = {
    # BUG: if .conda/environments.txt doesn't exist then this won't work
    # workaround for now `mkdir ~/.conda && touch ~/.conda/environments.txt`

    extraBackupArgs = [
      "--exclude-file /home/${config.oizys.user}/.config/restic/excludes.txt"
      "--exclude-file /home/${config.oizys.user}/.conda/environments.txt"
      "--verbose"
      "--one-file-system"
      "--tag systemd.timer"
    ];
    pruneOpts = [
      "--verbose"
      "--tag systemd.timer"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
    timerConfig = {
      OnCalendar = "00:05";
      Persistent = true;
      RandomizedDelaySec = "5h";
    };
  };
}
