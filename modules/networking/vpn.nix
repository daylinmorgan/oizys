{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOizysModule;
in mkOizysModule config "vpn" {
    environment.systemPackages = [pkgs.openconnect];
  }
