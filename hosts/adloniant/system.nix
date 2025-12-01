{
  config,
  enabled,
  ...
}:
{

  oizys.server = enabled;

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
    "/mnt/hdd" = {
      device = "/dev/disk/by-label/WD-1TB";
      fsType = "btrfs";
      options = [
        "subvol=@data"
        "noatime"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /data 0755 root root - -"
    "L /data/media - - - - /mnt/hdd/media"
    "L /data/torrents - - - - /mnt/hdd/torrents"
  ];

  sops = {
    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.wg-conf = {
      sopsFile = ../../secrets/secrets.yaml;
    };
  };

  networking.wg-quick.interfaces = {
    # AirVPN - North America
    air-na.configFile = config.sops.secrets.wg-conf.path;
  };

  services.openssh = enabled // {
    settings = {
      PasswordAuthentication = false;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # don't delete this you foo bar
  system.stateVersion = "25.11"; # Did you read the comment?
}
