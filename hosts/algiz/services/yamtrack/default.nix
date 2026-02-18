{ ... }:
{

  services.caddy.virtualHosts."yamtrack.dayl.in".extraConfig = ''
    reverse_proxy http://localhost:8565
  '';

  # do I need to bother with a separate network here?
  environment.etc = {
    "containers/systemd/yamtrack.network".text = ''
      [Network]
      NetworkName=yamtrack
    '';

    "containers/systemd/yamtrack-redis.container".text = ''
      [Unit]
      Description=Redis for Yamtrack

      [Container]
      ContainerName=yamtrack-redis
      Image=docker.io/library/redis:8-alpine
      Volume=/var/lib/yamtrack/redis:/data:Z,U
      Network=yamtrack.network

      [Service]
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';

    "containers/systemd/yamtrack.container".text = ''
      [Unit]
      Description=Yamtrack
      After=yamtrack-redis.service
      Requires=yamtrack-redis.service

      [Container]
      ContainerName=yamtrack
      # v0.24.11
      Image=ghcr.io/fuzzygrim/yamtrack@sha256:0cf6cfbaf160248636e5116cbdd587dd8060d91c976dbf44e8d0b565456ad8ff
      Environment=TZ=America/New_York
      Environment=REDIS_URL=redis://yamtrack-redis:6379
      Environment=URLS=https://yamtrack.dayl.in
      PublishPort=8565:8000
      Volume=/var/lib/yamtrack/db:/yamtrack/db:Z,U
      Network=yamtrack.network

      [Service]
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';
  };

  # Ensure the host directory for the bind mount exists
  systemd.tmpfiles.rules = [
    "d /var/lib/yamtrack/db 0750 root root -"
    # Redis default UID should be 999
    "d /var/lib/yamtrack/redis 0750 999 999 -"
  ];
}
