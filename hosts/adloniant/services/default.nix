{
  lib,
  pkgs,
  enabled,
  config,
  ...
}:

let
  inherit (builtins) attrNames concatStringsSep;
  servicesPorts = {
    qui = 7476;
    jellyfin = 8096;
    sonarr = 8989;
    radarr = 7878;
    prowlarr = 9696;
    qbittorrent = 8080;
    prismarr = 7070;
  };
  openPorts = false;
  # Most services listen on the host loopback; qbittorrent runs inside the
  # air-na VPN namespace and is reachable at the namespace bridge address.
  serviceHosts = {
    qbittorrent = "192.168.15.1";
  };
  makeLandingPage =
    subdomains:
    let
      links =
        subdomains
        |> map (name: ''<li><a href="http://${name}.home.dayl.in" rel="noreferrer">${name}</a></li>'')
        |> concatStringsSep "\n";
    in
    ''
      <!DOCTYPE html>
      <html>
      <head><title>home.dayl.in</title></head>
      <body>
      <h1>home.dayl.in</h1>
      <ul>${links}</ul>
      </body>
      </html>
    '';
  landingPage = pkgs.writeTextDir "index.html" (makeLandingPage (servicesPorts |> attrNames));
in
{
  imports = [
    ./prismarr
    ./qbittorrent # qbittorrent is VPN-confined; see this module
  ];

  sops.secrets.radarr-api = { };
  sops.secrets.sonarr-api = { };
  services = {
    fwupd = enabled;
    # flaresolverr = enabled;
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
        address = [
          "/home.dayl.in/192.168.50.17"
        ]
        ++ (servicesPorts |> attrNames |> map (name: "/${name}.home.dayl.in/192.168.50.17"));
        no-resolv = true;
        server = [
          "/ts.net/100.100.100.100" # forward tailscale traffic to tailscale
          "8.8.8.8"
          "8.8.4.4"
        ];
      };
    };
    recyclarr = enabled // {
      configuration =
        [
          "sonarr"
          "radarr"
        ]
        |> map (name: {
          inherit name;
          value = {
            ${name} = {
              api_key = {
                _secret = config.sops.secrets."${name}-api".path;
              };
              base_url = "http://localhost:${toString servicesPorts.${name}}";
            };
          };
        })
        |> lib.listToAttrs;
    };
    caddy = enabled // {
      logFormat = ''
        output file /var/log/caddy/access.log
      '';

      virtualHosts = {
        "http://home.dayl.in".extraConfig = ''
          root * ${landingPage}
          file_server
        '';
      }
      // (
        servicesPorts
        |> lib.mapAttrs' (
          name: port: {
            name = "http://${name}.home.dayl.in";
            value = {
              extraConfig = ''
                reverse_proxy http://${serviceHosts.${name} or "localhost"}:${toString port}
              '';
            };
          }
        )
      );
    };

    tailscale = enabled // {
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale-key.path;

      extraUpFlags = [
        "--accept-dns=true"
        "--advertise-routes=192.168.50.0/24"
      ];

    };
  };

  # let caddy talk to tailscale so certs work
  users.users.caddy.extraGroups = [ "tailscale" ];

  # also set by vpn-confinement?
  # Required for Tailscale subnet routing
  boot.kernel.sysctl = lib.mkDefault {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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
      # torrent inbound is handled inside the air-na VPN namespace
    ];
  };

}
