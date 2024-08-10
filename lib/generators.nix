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
    isNixFile
    flakeFromSystem
    ;
  inherit (lib.filesystem) listFilesRecursive;

  flake = flakeFromSystem "x86_64-linux";
  hostPath = host: ../. + "/hosts/${host}";
  # all nix files not including pkgs.nix
  # hostFiles = host: filter isNixFile (listFilesRecursive (hostPath host));

  hostFiles = host: host |> hostPath |> listFilesRecursive |> filter isNixFile;

  mkIso = nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.lix-module.nixosModules.default
      self.nixosModules.nix
      self.nixosModules.essentials
      self.nixosModules.iso
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
