{
  inputs,
  lib,
  self,
  hostName,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    oizysSettings
    tryPkgsFromFile
    listToAttrs
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
    niri

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
    server.enable = mkEnableOption "is server";
    docker.enable = mkEnableOption "enable docker support";

    packages = mkOption {
      type = lib.types.attrsOf lib.types.package;
      description = "attr set of all packages, for use with nix-eval-jobs by `oizys cache`";
    };
  };

  config = {
    networking.hostName = hostName;
    time.timeZone = "US/Central";
    nixpkgs.overlays = import ../overlays { inherit inputs lib; };
    oizys = oizysSettings hostName // {
      packages =
        config.environment.systemPackages
        |> map (drv: {
          name = drv.name;
          value = drv;
        })
        |> listToAttrs;
    };
    environment.systemPackages = tryPkgsFromFile { inherit hostName pkgs; };
  };
}
