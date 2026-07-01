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
        # record the flake revision that built this system so oizys can
        # report it at runtime (via `nixos-version --configuration-revision`)
        { system.configurationRevision = self.rev or self.dirtyRev or "dirty"; }
      ]
      ++ (selfModules "oizys")
      ++ (nixosModules "sops-nix")
      ++ [ (flake.modules "celler").cellerd ]
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
