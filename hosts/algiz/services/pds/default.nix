{ config, ... }:
{
  sops.secrets.pds-env = {
    sopsFile = ./secrets.yaml;
  };

  services.caddy.virtualHosts."bsky.dayl.in" = {
    serverAliases = [ "daylin.bsky.dayl.in" ];
    extraConfig = ''
      reverse_proxy http://localhost:6555
    '';
  };
  # services.caddy.virtualHosts."matrix.dayl.in".extraConfig = ''
  #   reverse_proxy http://localhost:8448
  # '';
  environment.etc."containers/systemd/pds.container".text = ''
    [Unit]
    Description=pds

    [Container]
    Image=ghcr.io/bluesky-social/pds:0.4.182
    Volume=/var/lib/pds/pds:/pds
    EnvironmentFile=${./env}
    EnvironmentFile=${config.sops.secrets.pds-env.path}
    PublishPort=6555:3000

    [Service]
    # Restart service when sleep finishes
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';
}
