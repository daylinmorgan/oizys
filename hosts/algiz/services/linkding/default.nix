{ ... }:
{
  services.caddy.virtualHosts."links.dayl.in".extraConfig = ''
    reverse_proxy http://localhost:9090
  '';
  environment.etc."containers/systemd/linkding.container" = {
    source = ./linkding.container;
  };
}
