{
  flake,
  enabled,
  config,
  ...
}:
let
  shareRoot = "/srv/copyparty";
in
{
  imports = [
    (flake.module "copyparty")
  ];

  # generated with sudo -u copyparty copyparty-hash
  # hash is of <account-name>:<password>
  sops.secrets.copyparty-admin = {
    owner = config.services.copyparty.user;
    group = config.services.copyparty.group;
    mode = "0400";
  };

  services.copyparty = enabled // {
    # handles injecting the account info into the config
    accounts = {
      admin.passwordFile = config.sops.secrets.copyparty-admin.path;
    };

    # Disable the module's default `/` volume
    volumes = { };

    globalExtraConfig = ''
      % ${./copyparty.conf}
    '';
  };

  # Required because `TemporaryFileSystem = "/:ro"` hides host paths not declared in `cfg.volumes`
  systemd.services.copyparty.serviceConfig.BindPaths = [
    shareRoot
  ];
  # Ensure the host directories exist with copyparty ownership
  systemd.tmpfiles.rules = [
    "d ${shareRoot} 0750 ${config.services.copyparty.user} ${config.services.copyparty.group} -"
    "d ${shareRoot}/root 0750 ${config.services.copyparty.user} ${config.services.copyparty.group} -"
    "d ${shareRoot}/pub 0750 ${config.services.copyparty.user} ${config.services.copyparty.group} -"
  ];

  services.caddy.virtualHosts."copy.dayl.in".extraConfig = ''
    reverse_proxy 127.0.0.1:3923
  '';

}
