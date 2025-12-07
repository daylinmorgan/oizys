{
  lib,
  enabled,
  config,
  ...
}:

let
  inherit (builtins) attrNames;
  servicesPorts = {
    jellyfin = 8096;
    sonarr = 8989;
    radarr = 7878;
    prowlarr = 9696;
    qbittorrent = 8080;
  };
  openPorts = false;
  torrentingPort = 38878;
in
{
  services = {
    fwupd = enabled;
    flaresolverr = enabled;
    qbittorrent = enabled // {
      inherit torrentingPort;
      openFirewall = openPorts;
    };
  }
  // (
    ''
      jellyfin
      sonarr
      radarr
      prowlarr
    ''
    |> lib.listifyMapToNamedAttrs (_: enabled // { openFirewall = openPorts; })
  )
  // {
    dnsmasq = {
      enable = true;
      settings = {

        domain = "home.dayl.in";
        local = "/home.dayl.in/";
        address = servicesPorts |> attrNames |> map (name: "/${name}.home.dayl.in/192.168.50.17");
        no-resolv = true;
        server = [
          "/ts.net/100.100.100.100" # forward tailscale traffic to tailscale
          "8.8.8.8"
          "8.8.4.4"
        ];
      };
    };
    caddy = enabled // {
      logFormat = ''
        output file /var/log/caddy/access.log
      '';

      virtualHosts =
        servicesPorts
        |> lib.mapAttrs' (
          name: port: {
            name = "http://${name}.home.dayl.in";
            value = {
              extraConfig = ''
                reverse_proxy http://localhost:${toString port}
              '';
            };
          }
        );
    };
    tailscale = enabled // {
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale-key.path;

      extraUpFlags = [
        # "--accept-dns=false"
        # "--exit-node-allow-lan-access"
      ];

    };
  };

  networking.nameservers = [
    "127.0.0.1" # local nameserver first
    "1.1.1.1"
  ];

  networking.firewall = enabled // {

    # why is this needed for tailscale?
    checkReversePath = "loose";

    # Port 53 must be opened for DNS queries.
    allowedUDPPorts = [ 53 ];

    allowedTCPPorts = [
      53 # Also allow TCP for DNS (used for large queries/zone transfers)
      80
      443
      torrentingPort
    ];
  };

}
