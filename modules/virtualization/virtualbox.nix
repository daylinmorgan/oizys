{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOizysModule;
in
  mkOizysModule config "vbox" {
    virtualisation.virtualbox = {
      host.enable = true;
    };
    users.extraGroups.vboxusers.members = ["daylin"];
  }
