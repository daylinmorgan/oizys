{ enableAttrs, ... }:
{
  oizys =
    (enableAttrs [
      "vpn"
      "desktop"
      "hyprland"
      "chrome"
      "docker"
      "nix-ld"
      "vbox"
      "backups"
    ])
    // {
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

  users.users.daylin.extraGroups = [ "audio" ];
}
