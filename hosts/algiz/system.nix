{
  enabled,
  ...
}:
{
  oizys = {
    rune.motd = enabled;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  networking.extraHosts = ''
    127.0.0.1 nix-cache.dayl.in
  '';

  # allow tcp connections for reverse proxy
  networking.firewall = enabled // {
    allowedTCPPorts = [
      80
      443
    ];

    # the rootful podman bsky couldn't access the network
    # this solution was found on reddit, unclear why it's even necessary though
    interfaces."podman[0-9]".allowedUDPPorts = [ 53 ];
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub = enabled // {
    device = "/dev/sda"; # or "nodev" for efi only
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
