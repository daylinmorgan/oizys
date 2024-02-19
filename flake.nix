{
  description = "nix begat oizys";

  inputs.inputs.url = "path:./inputs";

  # nixConfig = {
  #   extra-substituters = [
  #     "https://hyprland.cachix.org"
  #     "https://nixpkgs-wayland.cachix.org"
  #     "https://daylin.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  #     "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
  #     "daylin.cachix.org-1:fLdSnbhKjtOVea6H9KqXeir+PyhO+sDSPhEW66ClE/k="
  #   ];
  # };
  #
  outputs = {inputs, ...}: let
    lib = import ./lib {
      nixpkgs = inputs.inputs.nixpkgs;
      inputs = inputs;
    };
    inherit (lib) findModules buildHosts buildOizys;
  in {
    nixosModules = findModules ./modules;
    nixosConfigurations = buildHosts {};
    packages = buildOizys {};
  };
}
