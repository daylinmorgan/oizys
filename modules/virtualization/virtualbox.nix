{
  config,
  mkOizysModule,
  ...
}:
mkOizysModule config "vbox" {
  virtualisation.virtualbox = {
    host.enable = true;
  };
  users.extraGroups.vboxusers.members = ["daylin"];
}
