{
  inputs,
  pkgs,
  ...
}: {

  ## kodi
  users.extraUsers.kodi.isNormalUser = true;
  services.cage.user = "kodi";
  services.cage.program = "${pkgs.kodi-wayland}/bin/kodi-standalone";
  services.cage.enable = true;
  ##

  security.sudo.wheelNeedsPassword = false;
}
