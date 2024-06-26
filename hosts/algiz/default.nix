{
  self,
  pkgs,
  enabled,
  ...
}:
{
  imports = with self.nixosModules; [ restic ];

  oizys = {
    languages = [
      "nim"
      "node" # for docker langservers
      "python"
    ];
    rune.motd = enabled;

    docker = enabled;
    backups = enabled;
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = "/home/daylin/.config/restic/algiz-pass";
    paths = [
      "/home/daylin/services/git/"
      "/home/daylin/services/gotosocial/"
      "home/daylin/services/caddy"
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
