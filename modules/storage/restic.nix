{
  config,
  pkgs,
  mkOizysModule,
  ...
}:
mkOizysModule config "backups" {
  environment.systemPackages = with pkgs; [rclone];

  services.restic.backups.gdrive = {
    # BUG: if .conda/environments.txt doesn't exist then this won't work
    # workaround for now `mkdir ~/.conda && touch ~/.conda/environments.txt`

    extraBackupArgs = [
      "--exclude-file /home/daylin/.config/restic/excludes.txt"
      "--exclude-file /home/daylin/.conda/environments.txt"
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
