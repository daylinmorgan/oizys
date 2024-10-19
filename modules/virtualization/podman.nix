{
  config,
  pkgs,
  mkOizysModule,
  enabled,
  ...
}:
mkOizysModule config "podman" {

  # I'm not sure what this is doing, but it was in the old wiki...
  # Enable common container config files in /etc/containers
  virtualisation.containers = enabled;
  virtualisation = {
    podman = enabled // {
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      # dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    podman-tui # status of containers in the terminal
    podman-compose # start group of containers for dev
  ];
}
