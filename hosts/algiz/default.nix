{ enabled, ... }:
{
  oizys = {
    languages = [
      "nim"
      "node" # for docker langservers
      "python"
      "nushell"
    ];
    rune.motd = enabled;
    docker = enabled;
    backups = enabled;
    nix-ld = enabled;
  };

  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = "/home/daylin/.config/restic/algiz-pass";
    paths = [
      "/home/daylin/services/git/"
      "/home/daylin/services/gotosocial/"
      "/home/daylin/services/caddy/"
      "/home/daylin/services/wedding-website/"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users = {
    daylin = {
      extraGroups = [ "docker" ];
    };

    git = {
      isNormalUser = true;
    };
  };
}
