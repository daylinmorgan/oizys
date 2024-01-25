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

  users = {
    extraUsers = {
      daylin = {
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = ["wheel" "docker" "networkmanager"];
        initialPassword = "nix";
      };
    };
  };
}
