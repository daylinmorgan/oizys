{ enabled, config, ... }:
{
  oizys = {
    vpn = enabled;
    desktop = enabled;
    hyprland = enabled;
    chrome = enabled;
    docker = enabled;
    nix-ld = enabled // {
      overkill = enabled;
    };
    vbox = enabled;
    backups = enabled;
    hp-scanner = enabled;
    languages = [
      "misc"
      "nim"
      "node"
      "nushell"
      "python"
      "roc"
      "tex"
      "zig"
    ];
  };

  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = "/home/daylin/.config/restic/othalan-pass";
    paths = [
      "/home/daylin/stuff/"
      "/home/daylin/dev/"
    ];
  };

  users.users.${config.oizys.user}.extraGroups = [ "audio" ];
}
