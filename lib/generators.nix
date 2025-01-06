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
    flakeFromSystem
    listify
    readSettings
    hostFiles
    ;
  flake = flakeFromSystem "x86_64-linux";
  nixosModules = names: names |> listify |> map (n: inputs.${n}.nixosModules.default);
  selfModules = names: names |> listify |> map (n: self.nixosModules.${n});

  # generate anonymous module to set oizys settings from existing plaintext files

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
        ]
        ++ (selfModules ''oizys'')
        ++ (nixosModules ''lix-module|sops-nix'')
        ++ (hostFiles hostName);

      specialArgs = commonSpecialArgs // {
        inherit
          flake
          mkDefaultOizysModule
          mkOizysModule
          listify
          enableAttrs
          hostName
          readSettings
          ;
      };
    };
in
{
  inherit mkIso mkSystem;
}
