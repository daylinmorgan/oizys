{ enabled, ... }:
{

  security.sudo.wheelNeedsPassword = false;
  services.resolved = enabled;

  services.fail2ban = enabled // {
    maxretry = 5;
    bantime = "24h";
  };

  # # added to make using `pip install` work in docker build
  # networking.nameservers = [ "8.8.8.8"];

  # allow tcp connections for revsere proxy
  networking.firewall = enabled // {
    allowedTCPPorts = [
      80
      443
    ];
  };

  services.openssh = enabled // {
    settings.PasswordAuthentication = false;
  };

  # users.mutableUsers = false;

  # Use the GRUB 2 boot loader.
  boot.loader.grub = enabled // {
    device = "/dev/sda"; # or "nodev" for efi only
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
