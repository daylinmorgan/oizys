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
    ];
  };

  # git user handles the forgjo ssh authentication
  users.users.git.isNormalUser = true;

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
    # by default is accessible only by root:root which should work with above service
    secrets.restic-algiz = { };
  };
}
