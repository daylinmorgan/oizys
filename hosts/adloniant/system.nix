{
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
