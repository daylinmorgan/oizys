{ ... }:
let
  image = "docker.io/shoshuo/prismarr:latest";
in
{
    environment.etc."containers/systemd/prismarr.container".text = ''
    [Unit]
    Description=Prismarr
    After=network-online.target
    Wants=network-online.target

    [Container]
    ContainerName=prismarr
    Image=${image}

    # Z: Applies private unshared SELinux/SELinux-like labels
    # U: Automatically chowns the host dir to match the container's internal UID/GID
    Volume=/var/lib/prismarr/data:/var/www/html/var/data:Z,U
    PublishPort=7070:7070

    # Let Symfony trust requests coming from the host via Caddy
    Environment=TRUSTED_PROXIES=127.0.0.1,10.88.0.1,192.168.50.0/24

    # Optional runtime overrides
    Environment=TZ=America/New_York
    # Environment=PHP_MEMORY_LIMIT=1024M
    # Environment=PHP_MAX_EXECUTION_TIME=120

    [Service]
    TimeoutStopSec=30
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';

  # Ensure the host directory for the bind mount exists before Podman tries to mount it
  systemd.tmpfiles.rules = [
    "d /var/lib/prismarr/data 0750 root root -"
  ];
}
