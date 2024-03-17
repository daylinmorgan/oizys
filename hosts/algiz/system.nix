{lib, ...}: {
  users.motd = lib.mkRune {
    number = "6";
    rune = "algiz";
  };

  services.resolved.enable = true;

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
  };

  time.timeZone = "America/Chicago";

  networking.hostName = "algiz";
  # # added to make using `pip install` work in docker build
  # networking.nameservers = [ "8.8.8.8"];

  # allow tcp connections for revsere proxy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  users.mutableUsers = false;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
