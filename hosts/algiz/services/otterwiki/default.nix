{ ... }:
{

  services.caddy.virtualHosts."wiki.dayl.in".extraConfig = ''
    reverse_proxy http://localhost:8721
  '';

  # I don't actually use the "custom" files right now so this could exist as a standalone .container file
  environment.etc."containers/systemd/otterwiki.container".text = ''
    [Unit]
    Description=otterwiki

    [Container]
    Image=redimp/otterwiki:2-slim
    Volume=/var/lib/otterwiki/app-data/:/app-data:Z,U
    Volume=${./custom}:/app/otterwiki/static/custom:ro
    PublishPort=8721:8080

    [Service]
    # Restart service when sleep finishes
    Restart=always

    [Install]
    WantedBy=multi-user.target
  '';
}
