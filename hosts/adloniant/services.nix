{
  lib,
  enabled,
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
in
{
  services = {
    fwupd = enabled;
    flaresolverr = enabled;
    qbittorrent = enabled // {
      torrentingPort = 38878;
      openFirewall = true;
    };
  }
  // (
    ''
      jellyfin
      sonarr
      radarr
      prowlarr
    ''
    |> lib.listifyMapToNamedAttrs (_: enabled // { openFirewall = true; })
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
  };

  networking.nameservers = [
    "127.0.0.1" # local nameserver first
    "1.1.1.1"
  ];

  networking.firewall = enabled // {

    # Port 53 must be opened for DNS queries.
    # Critical: DNS primarily uses UDP.
    allowedUDPPorts = [ 53 ];

    # Recommended: Also allow TCP for DNS (used for large queries/zone transfers)
    allowedTCPPorts = [
      53
      80
      443
    ];

    # Optional: Limit access to your local subnet (more secure)
    # should I switch to these?
    # allowedTCPPortRanges =
  };
}
