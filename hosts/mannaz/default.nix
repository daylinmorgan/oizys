{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    desktop
    nvim

    gui
    nix-ld
  ];

  users.users.daylin.extraGroups = ["docker"];
}
