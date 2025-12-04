{ config, lib, ... }:
let
  users = [ "daylin" ];
in
{
  sops.secrets.pds-env = {
    sopsFile = ./secrets.yaml;
  };

  services.caddy.virtualHosts =
    [
      "bsky.dayl.in"
    ]
    |> lib.mapToNamedAttrs (name: {
      serverAliases = users |> map (u: "${u}.bsky.dayl.in");
      extraConfig = "reverse_proxy http://localhost:6555";
    });

  environment.etc."containers/systemd/pds.container".text = ''
    [Unit]
    Description=pds

    [Container]
    Image=ghcr.io/bluesky-social/pds:0.4.193
    Volume=/var/lib/pds/pds:/pds:Z,U
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
