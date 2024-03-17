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

  buildOizys = _:
    forAllSystems (
      pkgs: let
        pkg = pkgs.callPackage ../oizys {};
      in {
        oizys = pkg;
        default = pkg;
      }
    );

  mkSystem = hostname:
    nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          ../modules/common.nix
          ../overlays
        ]
        ++ filter
        isNixFile
        (listFilesRecursive (../. + "/hosts/${hostname}"));

      specialArgs = {inherit inputs lib self;};
    };
  mapHosts = dir: mapAttrs (name: _: mkSystem name) (readDir dir);
  findModules = _: listToAttrs (findModulesList ../modules);

  oizysFlake = _: {
    nixosModules = findModules {};
    nixosConfigurations = mapHosts ../hosts;
    packages = buildOizys {};
    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
