{
  inputs,
  lib,
  self,
  hostName,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption loadOverlays;
in
{
  imports = with self.nixosModules; [
    users
    runes
    nix

    essentials
    cli
    nvim
    vpn
    gpg

    lock
    qtile
    hyprland

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
  };
}
