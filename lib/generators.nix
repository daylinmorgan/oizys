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
    listify
    ;
  inherit (lib.filesystem) listFilesRecursive;

  flake = flakeFromSystem "x86_64-linux";
  hostPath = host: ../. + "/hosts/${host}";
  # all nix files not including pkgs.nix
  # hostFiles = host: filter isNixFile (listFilesRecursive (hostPath host));
  hostFiles = host: host |> hostPath |> listFilesRecursive |> filter isNixFile;

  commonSpecialArgs = {
    inherit
      self
      inputs
      lib
      enabled
      ;
  };

  mkIso = nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.lix-module.nixosModules.default
      self.nixosModules.nix
      self.nixosModules.essentials
      self.nixosModules.iso
    ];
    specialArgs = commonSpecialArgs;
  };

  mkSystem =
    hostName:
    nixosSystem {
      system = "x86_64-linux";
      modules = [
        ../modules/oizys.nix
        inputs.lix-module.nixosModules.default
        inputs.hyprland.nixosModules.default
        inputs.comin.nixosModules.comin
      ] ++ (hostFiles hostName);

      specialArgs = commonSpecialArgs // {
        inherit
          mkDefaultOizysModule
          mkOizysModule
          listify
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
