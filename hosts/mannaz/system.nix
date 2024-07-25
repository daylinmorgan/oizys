{
  config,
  enabled,
  ...
}:
{
  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = enabled;
    efi.canTouchEfiVariables = true;
  };

  # latest kernel was hanging on boot?
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  # this device doesn't have enough ram :/
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 24 * 1024;
    }
  ];

  # deprecated?
  # hardware.opengl = enabled // {
  #   driSupport = true;
  #   driSupport32Bit = true;
  #   extraPackages = with pkgs; [ libGL ];
  #   setLdLibraryPath = true;
  # };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting = enabled;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement = enabled // {
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      finegrained = false;
    };

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.openssh = enabled;

  # networking.wireless.enable = true;
  # networking.networkmanager.enable = true;

  networking.firewall.allowedTCPPorts = [
    7865
    7860
  ];

  security.sudo.wheelNeedsPassword = false;

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
