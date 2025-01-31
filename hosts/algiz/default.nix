{
  config,
  enabled,
  pkgs,
  ...
}:
{

  oizys = {
    rune.motd = enabled;
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  # maybe I don't need to use root and can use this strategy?
  # https://wiki.nixos.org/wiki/Restic#Security_Wrapper
  # would this make it possible for me to run the binary as my 'normal user'?
  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = config.sops.secrets.restic-algiz.path;
    paths = [
      "/home/daylin/services/git/"
      "/home/daylin/services/gotosocial/"
      "/home/daylin/services/caddy/"
      "/home/daylin/services/wedding-website/"
      "/home/daylin/services/bsky-pds/"
    ];
  };

  # git user handles the forgjo ssh authentication
  users.users.git.isNormalUser = true;
}
