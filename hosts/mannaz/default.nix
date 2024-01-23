{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    ./system.nix
    ./motd.nix

    cli
    desktop
    dev
    gui
    nix
    nix-ld
    nvim
    virtualization
  ];

  environment.systemPackages = with pkgs; [
    nix-output-monitor

    (vivaldi.override {
      proprietaryCodecs = true;
      # enableWidevine = true;
    })
  ];

  users = {
    defaultUserShell = pkgs.zsh;
    extraUsers = {
      daylin = {
        isNormalUser = true;
        extraGroups = ["wheel" "docker" "networkmanager"];
        useDefaultShell = true;
        initialPassword = "nix";
      };
    };
  };
}
