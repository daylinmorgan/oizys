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

  hostFiles = host: host |> hostPath |> listFilesRecursive |> filter isNixFile;

  nixosModules = names: names |> listify |> map (n: inputs.${n}.nixosModules.default);
  selfModules = names: names |> listify |> map (n: self.nixosModules.${n});

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
    modules = (nixosModules "lix-module") ++ (selfModules "nix|essentials|iso");
    specialArgs = commonSpecialArgs;
  };

  mkSystem =
    hostName:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          inputs.comin.nixosModules.comin
        ]
        ++ (selfModules ''oizys'')
        ++ (nixosModules ''lix-module|hyprland|sops-nix'')
        ++ (hostFiles hostName);

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
