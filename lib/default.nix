inputs@{
  nixpkgs,
  treefmt-nix,
  self,
  ...
}:
let
  lib = nixpkgs.lib.extend (import ./extended.nix inputs);

  inherit (builtins) mapAttrs readDir listToAttrs;
  inherit (lib)
    genAttrs
    pkgFromSystem
    loadOverlays
    enabled
    listify
    enableAttrs
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

  evalTreeFmt =
    pkgs:
    (treefmt-nix.lib.evalModule pkgs (
      { ... }:
      {
        projectRootFile = "flake.nix";
        # don't warn me about missing formatters
        settings.excludes = [
          # likely to be nnl lockfiles
          "pkgs/**/lock.json"
          "hosts/**/secrets.yaml"
        ];
        settings.on-unmatched = "debug";
        programs = "prettier|nixfmt" |> listify |> enableAttrs;
      }
    ));

  oizysFlake = {
    templates = {
      dev = {
        path = ../templates/dev;
        description = "a basic dev shell";
      };
      default = self.templates.dev;
    };
    nixosModules = listToAttrs (findModulesList ../modules);
    nixosConfigurations = mapAttrs (name: _: mkSystem name) (readDir ../hosts);
    packages = forAllSystems (
      pkgs:
      rec {
        default = oizys;
        oizys = pkgs.callPackage ../pkgs/oizys { };
        iso = mkIso.config.system.build.isoImage;
        lix = pkgFromSystem pkgs.system "lix-module";
      }
      // (inheritFlakePkgs pkgs [
        "pixi"
        "f1multiviewer"
        "tsm"
      ])
      // (import ../pkgs { inherit pkgs; })
    );

    devShells = forAllSystems (pkgs: {
      oizys = pkgs.mkShell {
        packages = with pkgs; [
          openssl
          nim
          self.packages.${pkgs.system}.nimble
        ];
      };
    });
    checks = forAllSystems (
      pkgs:
      import ./checks.nix {
        inherit inputs lib self;
        system = pkgs.system;
      }
      // {
        formatter = (evalTreeFmt pkgs).config.build.check self;
      }
    );
    formatter = forAllSystems (pkgs: (evalTreeFmt pkgs).config.build.wrapper);
    # formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
  };
in
{
  inherit oizysFlake;
}
