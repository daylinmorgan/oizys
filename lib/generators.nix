{
  inputs,
  self,
  lib,
  ...
}:
let
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

  commonSpecialArgs = {
    inherit
      self
      inputs
      lib
      flake
      enabled
      ;
  };

  mkIso = nixosSystem {
    modules =
      [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
      ]
      ++ (nixosModules "lix-module")
      ++ (selfModules "essentials|iso");
    specialArgs = commonSpecialArgs;
  };

  mkSystem =
    hostName:
    nixosSystem {
      modules =
        [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
        ]
        ++ (selfModules ''oizys'')
        ++ (nixosModules ''lix-module|sops-nix'')
        ++ (hostFiles hostName);

      specialArgs = commonSpecialArgs // {
        inherit
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
