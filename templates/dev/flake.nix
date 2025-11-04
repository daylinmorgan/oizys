{
  description = "";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) genAttrs;
      systems = [ "x86_64-linux" ]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      forSystem = system: fn: fn system (import nixpkgs { inherit system; });
      forAllSystems =
        fn:
        genAttrs systems (
          system:
          fn system (
            import nixpkgs {
              inherit system;
            }
          )
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # insert packages here
          ];
        };
      });
    };
}
