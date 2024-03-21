{
  inputs,
  self,
}: let
  inherit (inputs) nixpkgs;
  lib = nixpkgs.lib.extend (import ./extended.nix);

  inherit (builtins) mapAttrs readDir filter listToAttrs;
  inherit (lib) nixosSystem genAttrs isNixFile;
  inherit (lib.filesystem) listFilesRecursive;

  inherit (import ./find-modules.nix {inherit lib;}) findModulesList;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = ["x86_64-linux"];
in rec {
  forAllSystems = f: genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

  nixosModules = listToAttrs (findModulesList ../modules);

  mkSystem = hostname:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          ../modules/oizys.nix
          ../overlays
        ]
        ++ filter
        isNixFile
        (listFilesRecursive (../. + "/hosts/${hostname}"));

      specialArgs = {inherit inputs lib self;};
    };

  oizysHosts = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
  oizysPkg = forAllSystems (pkgs:
   rec {
      oizys = pkgs.callPackage ../oizys {};
      default = oizys;
    }
  );
  devShells = forAllSystems (
    pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [git deadnix];
      };
    }
  );

  oizysFlake = {
    nixosModules = nixosModules;
    nixosConfigurations = oizysHosts;
    packages = oizysPkg;
    devShells = devShells;
    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
