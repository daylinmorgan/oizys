{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (builtins) filter;
  inherit (lib)
    nixosSystem
    mkDefaultOizysModule
    mkOizysModule
    enabled
    enableAttrs
    pkgsFromSystem
    pkgFromSystem
    overlayFrom
    isNixFile
    flakeFromSystem
    ;
  inherit (lib.filesystem) listFilesRecursive;

  # pkgFrom = pkgFromSystem "x86_64-linux";
  # pkgsFrom = pkgsFromSystem "x86_64-linux";
  flake = flakeFromSystem "x86_64-linux";
  hostPath = host: ../. + "/hosts/${host}";
  # all nix files not including pkgs.nix
  hostFiles = host: filter isNixFile (listFilesRecursive (hostPath host));

  mkIso = nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.nix
      self.nixosModules.essentials
      (
        { pkgs, modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          environment.systemPackages = (with pkgs; [ neovim ]) ++ [ (flake.pkg "self") ];
        }
      )
    ];
    specialArgs = {
      inherit
        inputs
        lib
        self
        enabled
        ;
    };
  };

  mkSystem =
    hostName:
    nixosSystem {
      system = "x86_64-linux";
      modules = [
        ../modules/oizys.nix
        ../overlays
        inputs.lix-module.nixosModules.default
        inputs.hyprland.nixosModules.default
      ] ++ (hostFiles hostName);

      specialArgs = {
        inherit
          inputs
          lib
          self
          mkDefaultOizysModule
          mkOizysModule
          enabled
          enableAttrs
          hostName
          flake
          ;
      };
    };
in
{
  inherit mkIso mkSystem;
}
