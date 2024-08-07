inputs@{ nixpkgs, self, ... }:
let
  lib = nixpkgs.lib.extend (import ./extended.nix inputs);

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib) genAttrs pkgFromSystem pkgsFromSystem;

  inherit (import ./find-modules.nix { inherit lib; }) findModulesList;
  inherit (import ./generators.nix { inherit lib self inputs; }) mkIso mkSystem;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];
  forAllSystems = f: genAttrs supportedSystems (system: f (import nixpkgs { inherit system; }));
  inheritFlakePkgs =
    pkgs: flakes:
    listToAttrs (
      map (name: {
        inherit name;
        value = pkgFromSystem pkgs.system name;
      }) flakes
    );

  oizysFlake = {
    nixosModules = listToAttrs (findModulesList ../modules);
    nixosConfigurations = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
    packages = forAllSystems (
      pkgs:
      rec {
        default = oizys-cli;
        oizys-cli = pkgs.callPackage ../pkgs/oizys { };
        iso = mkIso.config.system.build.isoImage;
        roc = (pkgsFromSystem pkgs.system "roc").full;
      }
      // (inheritFlakePkgs pkgs [
        "pixi"
        "f1multiviewer"
        "tsm"
      ])
    );

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
        inherit inputs lib self;
        system = pkgs.system;
      }
    );
    formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
  };
in
{
  inherit oizysFlake;
}
