{
  description = "";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) genAttrs;
      systems = [ "x86_64-linux" ]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      forSystem = f: system: f system (import nixpkgs { inherit system; });
      forAllSystems = f: genAttrs systems (forSystem f);
    in
    {
      devShells = forAllSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # insert packages here
            ];
          };
        }
      );
    };
}
