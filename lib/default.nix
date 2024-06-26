inputs:
let
  inherit (inputs) nixpkgs self;
  lib = nixpkgs.lib.extend (import ./extended.nix);

  inherit (builtins)
    mapAttrs
    readDir
    filter
    listToAttrs
    ;
  inherit (lib)
    nixosSystem
    genAttrs
    isNixFile
    mkDefaultOizysModule
    mkOizysModule
    enabled
    ;
  inherit (lib.filesystem) listFilesRecursive;

  inherit (import ./find-modules.nix { inherit lib; }) findModulesList;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];

  forAllSystems = f: genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));

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
          hostName
          ;
      };
    };

in
{
  oizysFlake = {
    nixosModules = listToAttrs (findModulesList ../modules);
    nixosConfigurations = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
    packages = forAllSystems (pkgs: rec {
      oizys-go = pkgs.callPackage ../pkgs/oizys {};
      default = oizys-go;
    });
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git
          deadnix
        ];
      };
    });
    checks = forAllSystems (
      pkgs:
      import ./checks.nix {
        inherit inputs;
        system = pkgs.system;
      }
    );
    formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
  };
}
