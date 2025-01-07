{ enabled, ... }:
{
  oizys = {
    rune.motd = enabled;
  };

  # Enable the X11 windowing system.
  services.xserver = enabled // {
    displayManager.startx = enabled;
    windowManager.qtile = enabled;
  };
}
