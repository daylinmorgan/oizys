{
  self,
  enabled,
  ...
}: {
  imports = with self.nixosModules; [
    nix-ld
  ];

  oizys = {
    desktop = enabled;
    nix-ld = enabled;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    windowManager.qtile.enable = true;
  };

  users.users.daylin.extraGroups = ["docker"];
}
