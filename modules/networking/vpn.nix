{
  config,
  pkgs,
  mkOizysModule,
  ...
}:
mkOizysModule config "vpn" {
  environment.systemPackages = [pkgs.openconnect];
}
