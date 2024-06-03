{
  pkgs,
  config,
  mkOizysModule,
  ...
}:
mkOizysModule config "docker" {
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [ lazydocker];
}
