{
  inputs,
  pkgs,
  ...
}: {

  ## kodi
  # users.extraUsers.kodi.isNormalUser = true;
  # services.cage.user = "kodi";
  # services.cage.program = "${pkgs.kodi-wayland}/bin/kodi-standalone";
  # services.cage.enable = true;
  
  services.xserver.enable = true;
  services.xserver.desktopManager.kodi.enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "kodi";
  users.extraUsers.kodi.isNormalUser = true;

  # This may be needed to force Lightdm into 'autologin' mode.
  # Setting an integer for the amount of time lightdm will wait
  # between attempts to try to autologin again. 
  services.xserver.displayManager.lightdm.autoLogin.timeout = 3;
  ##

  security.sudo.wheelNeedsPassword = false;
}
