{self, ...}: {
  imports = with self.nixosModules; [
    nix-ld
  ];

  desktop.enable = true;
  cli.enable = true;
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    windowManager.qtile.enable = true;
  };

  users.users.daylin.extraGroups = ["docker"];
}
