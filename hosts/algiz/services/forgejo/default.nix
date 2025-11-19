{
  config,
  pkgs,
  lib,
  ...
}:
let
  gitUid = toString config.users.users.git.uid;
  gitGid = toString config.users.groups.users.gid;
  secretsNames = [
    "security-internal-token"
    "server-lfs-jwt-secret"
    "oauth2-jwt-secret"
  ];
  secretsVolumes =
    secretsNames
    |> map (name: ''Volume=${config.sops.secrets."forgejo-${name}".path}:/etc/forgejo/secrets/${name}'')
    |> lib.concatStringsSep "\n";
  sshPort = toString 2222;

  catppuccin-assets = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "catppuccin-assets";
    version = "1.0.2";
    src = pkgs.fetchzip {
      url = "https://github.com/catppuccin/gitea/releases/download/v${finalAttrs.version}/catppuccin-gitea.tar.gz";
      sha256 = "sha256-rZHLORwLUfIFcB6K9yhrzr+UwdPNQVSadsw6rg8Q7gs=";
      stripRoot = false;
    };

    dontBuild = true;
    installPhase = ''
      mkdir -p $out/css
      cp -r $src/* $out/css/
    '';
  });
in
{

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p ${sshPort} -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  # git user handles the forgjo ssh authentication
  users.users.git = {
    isNormalUser = true;
    uid = 1001;
  };

  sops.secrets =
    secretsNames
    |> map (name: {
      name = "forgejo-${name}";
      value = {
        sopsFile = ./secrets.yaml;
        owner = config.users.users.git.name;
        group = config.users.users.git.group;
      };
    })
    |> lib.listToAttrs;

  services.caddy.virtualHosts."git.dayl.in".extraConfig = ''
    import no-ai
    reverse_proxy http://localhost:3000
  '';

  environment.etc."containers/systemd/forgejo.container".text = ''
    [Unit]
    Description=forgejo

    [Container]
    Image=codeberg.org/forgejo/forgejo:13.0.1
    # git user ids
    Environment=USER_UID=${gitUid}
    Environment=USER_GID=${gitGid}
    Environment=FORGEJO_CUSTOM=/etc/forgejo/custom

    ${secretsVolumes}
    Volume=${./app.ini}:/etc/forgejo/custom/conf/app.ini:Z
    Volume=${catppuccin-assets}/css:/etc/forgejo/custom/public/assets/css
    Volume=${./public/assets/img}:/etc/forgejo/custom/public/assets/img
    Volume=/var/lib/forgejo/data:/data:Z
    Volume=/home/git/.ssh:/data/git/.ssh:rw,z
    Volume=/etc/timezone:/etc/timezone:ro
    Volume=/etc/localtime:/etc/localtime:ro

    PublishPort=3000:3000
    PublishPort=${sshPort}:22

    [Service]
    # Restart service when sleep finishes
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';
}
