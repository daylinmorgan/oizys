{ enabled, ... }:
{
  oizys = {
    desktop = enabled;
    nix-ld = enabled;
    rune.motd = enabled;
    docker = enabled;
  };

  # Enable the X11 windowing system.
  services.xserver = enabled // {
    displayManager.startx = enabled;
    windowManager.qtile = enabled;
  };

}
