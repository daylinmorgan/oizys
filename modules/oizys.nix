{
  inputs,
  lib,
  self,
  hostName,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    loadOverlays
    oizysSettings
    tryPkgsFromFile
    ;
in
{
  imports = with self.nixosModules; [
    users
    runes
    essentials

    nix-improved
    cli
    nvim
    vpn
    gpg

    lock
    qtile
    hyprland
    plasma

    virtualbox
    docker
    podman

    gui
    fonts
    hp-scanner

    languages

    # programs
    chrome
    vscode

    nix-ld
    restic

    llm

    utils
  ];

  options.oizys = {
    user = mkOption {
      type = lib.types.str;
      default = "daylin";
      description = "main user account";
    };
    desktop.enable = mkEnableOption "is desktop";
    docker.enable = mkEnableOption "enable docker support";
  };
  config = {
    networking.hostName = hostName;
    time.timeZone = "US/Central";
    nixpkgs.overlays = import ../overlays { inherit inputs loadOverlays; };
    oizys = oizysSettings hostName;
    environment.systemPackages = tryPkgsFromFile { inherit hostName pkgs; };
  };
}
