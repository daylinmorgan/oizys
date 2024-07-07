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
    isNixFile
    mkDefaultOizysModule
    mkOizysModule
    enabled
    enableAttrs
    ;
  inherit (lib.filesystem) listFilesRecursive;

  mkIso = nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.nixosModules.nix
      self.nixosModules.essentials
      (
        { pkgs, modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          environment.systemPackages = with pkgs; [ neovim ];
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
      ] ++ filter isNixFile (listFilesRecursive (../. + "/hosts/${hostName}"));
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
          ;
      };
    };
in
{
  inherit mkIso mkSystem;
}
