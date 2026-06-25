{
  inputs,
  config,
  enabled,
  pkgs,
  ...
}:
let
  # Must match the forwarded port configured in AirVPN's WireGuard config.
  torrentingPort = 38878;
  # vpn-confinement's default namespace address; qbittorrent's WebUI binds here
  # and Caddy reaches it via the portMapping below.
  namespaceAddress = "192.168.15.1";
in
{
  imports = [ inputs.vpn-confinement.nixosModules.default ];

  # Only this namespace egresses through AirVPN. Reuses the same wg-quick config
  # (wg-conf) that previously drove the host-wide wg-quick interface.
  # NOTE: namespace name is limited to 7 characters.
  vpnNamespaces.air-na = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.wg-conf.path;

    # Who may reach the mapped ports: the LAN and the host loopback (Caddy).
    accessibleFrom = [
      "192.168.50.0/24"
      "127.0.0.1"
    ];

    # Expose qbittorrent's WebUI from inside the namespace to the host so Caddy
    # can reverse_proxy http://localhost:8080 as before.
    portMappings = [
      {
        from = 8080;
        to = 8080;
      }
    ];

    # Inbound torrent traffic allowed through the VPN interface.
    openVPNPorts = [
      {
        port = torrentingPort;
        protocol = "both";
      }
    ];
  };

  systemd.services.qbittorrent = {
    # Attach the unit to the namespace. If the tunnel drops, the unit has no
    # route out -> kill switch.
    vpnConfinement = {
      enable = true;
      vpnNamespace = "air-na";
    };
    # Install the sops-rendered config before qbittorrent starts (replaces the
    # module's own serverConfig install, which is disabled now serverConfig={}).
    restartTriggers = [ config.sops.templates."qBittorrent.conf".content ];
    serviceConfig.ExecStartPre = [
      "${pkgs.coreutils}/bin/install -Dm600 ${config.sops.templates."qBittorrent.conf".path} ${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf"
    ];
  };

  services.qbittorrent = enabled // {
    inherit torrentingPort;
    openFirewall = false; # firewall is handled inside the namespace
    webuiPort = 8080;
    # serverConfig left at its default ({}) so the module installs nothing; the
    # full qBittorrent.conf is rendered at runtime by the sops template below,
    # keeping the WebUI password hash out of git and the nix store.
  };

  # WebUI Password_PBKDF2 hash (the @ByteArray(...) value).
  sops.secrets.qbittorrent-pass = { };

  # Render qBittorrent.conf at activation with the password substituted in.
  # Output lives in /run (tmpfs), 0600, owned by qbittorrent -> never in
  # git or the world-readable nix store. Nested `Key\Sub` mirrors the INI.
  sops.templates."qBittorrent.conf" = {
    owner = config.services.qbittorrent.user;
    mode = "0600";
    content = ''
      [BitTorrent]
      Session\AddTorrentStopped=false
      Session\DefaultSavePath=/data/torrents
      Session\DisableAutoTMMByDefault=false
      Session\DisableAutoTMMTriggers\CategorySavePathChanged=false
      Session\DisableAutoTMMTriggers\DefaultSavePathChanged=false
      Session\TorrentContentLayout=Subfolder
      Session\QueueingSystemEnabled=true
      Session\Port=${toString torrentingPort}
      Session\SSL\Port=58483
      Session\ShareLimitAction=Stop

      [Preferences]
      WebUI\Address=${namespaceAddress}
      WebUI\AlternativeUIEnabled=true
      WebUI\CSRFProtection=false
      WebUI\HostHeaderValidation=false
      WebUI\Password_PBKDF2=${config.sops.placeholder.qbittorrent-pass}
      WebUI\RootFolder=${pkgs.vuetorrent}/share/vuetorrent
    '';
  };
}
