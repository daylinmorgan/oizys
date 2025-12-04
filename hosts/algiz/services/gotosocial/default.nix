{ ... }:
{

  services.caddy.virtualHosts."gts.dayl.in".extraConfig = ''
    # Optional, but recommended, compress the traffic using proper protocols
    encode zstd gzip

    reverse_proxy * http://localhost:3758 {
      # Flush immediatly, to prevent buffered response to the client
      flush_interval -1
    }
  '';

  environment.etc."containers/systemd/gotosocial.container" = {
    text = ''
      [Unit]
      Description=gotosocial

      [Container]
      Image=docker.io/superseriousbusiness/gotosocial:0.20.2
      Volume=/var/lib/gotosocial/fonts:/gotosocial/web/assets/myfonts/:Z,U
      Volume=/var/lib/gotosocial/data:/gotosocial/storage:Z,U
      PublishPort=3758:3758
      EnvironmentFile=${./env}

      [Service]
      # Restart service when sleep finishes
      Restart=always

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
