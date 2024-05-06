{
  pkgs,
  enabled,
  mkRune,
  ...
}:
{
  networking.networkmanager = enabled;
  services.printing = enabled;
  services.fwupd = enabled;
  hardware.bluetooth = enabled // {
    powerOnBoot = true;
  };

  # https://github.com/NixOS/nixos-hardware/blob/c478b3d56969006e015e55aaece4931f3600c1b2/lenovo/thinkpad/x1/9th-gen/default.nix
  # https://github.com/NixOS/nixos-hardware/blob/c478b3d56969006e015e55aaece4931f3600c1b2/common/pc/ssd/default.nix
  services.fstrim = enabled;

  # rtkit is optional but recommended
  security.rtkit = enabled;
  services.pipewire = enabled // {
    audio = enabled;
    pulse = enabled;
    alsa = enabled // {
      support32Bit = true;
    };
  };

  environment.systemPackages = with pkgs; [ pamixer ];

  services.getty = {
    greetingLine = mkRune {
      rune = "othalan";
      runeKind = "ascii";
    };
    helpLine = "";
  };

  networking.hostName = "othalan";
  time.timeZone = "US/Central";

  # catppuccin/tty move to "module"
  boot.kernelParams = [
    "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
    "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
    "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
  ];

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  boot.loader = {
    systemd-boot = enabled // {
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
