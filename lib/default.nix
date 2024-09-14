inputs@{ nixpkgs, self, ... }:
let
  lib = nixpkgs.lib.extend (import ./extended.nix inputs);

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib)
    genAttrs
    pkgFromSystem
    pkgsFromSystem
    loadOverlays
    ;

  inherit (import ./find-modules.nix { inherit lib; }) findModulesList;
  inherit (import ./generators.nix { inherit lib self inputs; }) mkIso mkSystem;
  #supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
  supportedSystems = [ "x86_64-linux" ];

  forAllSystems =
    fn:
    genAttrs supportedSystems (
      system:
      fn (
        import nixpkgs {
          inherit system;
          overlays = (import ../overlays { inherit inputs loadOverlays; });
        }
      )
    );

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
        default = oizys-nim;
        oizys-nim = pkgs.callPackage ../pkgs/oizys-nim { };
        oizys-go = pkgs.callPackage ../pkgs/oizys { };
        nimlangserver = pkgs.callPackage ../pkgs/nimlangserver { };
        nph = pkgs.callPackage ../pkgs/nph { };
        iso = mkIso.config.system.build.isoImage;
        # roc = (pkgsFromSystem pkgs.system "roc").full;
      }
      // (inheritFlakePkgs pkgs [
        "pixi"
        "f1multiviewer"
        "tsm"
      ])
    );

    devShells = forAllSystems (pkgs: {
      oizys = pkgs.mkShell {
        packages = with pkgs; [
          openssl
          nim
          nimble
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
