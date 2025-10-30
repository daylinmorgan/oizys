{ enabled, ... }:
{

  # # added to make using `pip install` work in docker build
  # networking.nameservers = [ "8.8.8.8"];

  networking.extraHosts = ''
    127.0.0.1 nix-cache.dayl.in
  '';

  # allow tcp connections for reverse proxy
  networking.firewall = enabled // {
    allowedTCPPorts = [
      80
      443
    ];
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub = enabled // {
    device = "/dev/sda"; # or "nodev" for efi only
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
