{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    desktop

    nix-ld
  ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    windowManager.qtile.enable = true;
  };

  cli.enable = true;
  users.users.daylin.extraGroups = ["docker"];
programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  }

