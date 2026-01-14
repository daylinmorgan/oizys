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
    disabled
    enableAttrs
    flakeFromSystem
    listify
    readSettings
    hostFiles
    hostSystem
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
      disabled
      ;
  };

  # should this have sops-nix too?
  mkIso =
    system:
    nixosSystem {
      system = system;
      modules = [
        { nixpkgs.hostPlatform = system; }
      ]
      ++ (selfModules "essentials|iso|lix");
      specialArgs = commonSpecialArgs;
    };

  mkSystem =
    hostName:
    let
      system = hostSystem hostName;
    in
    nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.hostPlatform = system; }
      ]
      ++ (selfModules "oizys")
      ++ (nixosModules "sops-nix")
      ++ (hostFiles hostName)
      ++ (if lib.data.lixModule then (nixosModules "lix-module") else (selfModules "lix"));

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
