{ config, pkgs, ... }:
let
  gitUid = toString config.users.users.git.uid;
  gitGid = toString config.users.groups.users.gid;
in
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  # git user handles the forgjo ssh authentication
  users.users.git = {
    isNormalUser = true;
    uid = 1001;
  };

  sops.secrets.forgejo-app-ini = {
    owner = config.users.users.git.name;
    group = config.users.users.git.group;
  };

  environment.etc."containers/systemd/forgejo.container".text = ''
    [Unit]
    Description=forgejo

    [Container]
    Image=codeberg.org/forgejo/forgejo:13.0.1
    # git user ids
    Environment=USER_UID=${gitUid}
    Environment=USER_GID=${gitGid}
    Environment=FORGEJO_CUSTOM=/etc/forgejo/custom
    Volume=${config.sops.secrets.forgejo-app-ini.path}:/etc/forgejo/custom/conf/app.ini:Z
    Volume=${./public}:/etc/forgejo/custom/public
    Volume=/opt/forgejo/data:/data:Z
    Volume=/home/git/.ssh:/data/git/.ssh:rw,z
    Volume=/etc/timezone:/etc/timezone:ro
    Volume=/etc/localtime:/etc/localtime:ro
    PublishPort=3000:3000
    PublishPort=2222:22

    [Service]
    # Restart service when sleep finishes
    Restart=unless-stopped

    [Install]
    WantedBy=multi-user.target
  '';
}
