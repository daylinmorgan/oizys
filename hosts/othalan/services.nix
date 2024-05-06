{ pkgs, ... }:
let
  notes-git = ''${pkgs.git}/bin/git -C /home/daylin/stuff/notes'';
in
{
  systemd.services.notes-bot = {
    description = "auto commit changes to notes";
    serviceConfig = {
      Type = "oneshot";
      User = "daylin";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '${notes-git} commit -m ":memo: :robot: $(${pkgs.coreutils}/bin/date +\'%%T\')" --no-gpg-sign -- notes'
      '';
    };
  };
  systemd.timers.notes-bot-timer = {
    description = "run notes commit service";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "notes-bot.service";
    };
  };
}
