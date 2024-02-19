{
  description = "nix begat oizys";

  inputs.inputs.url = "github:daylinmorgan/oizys?dir=inputs";

  outputs = {
    inputs,
    self,
    ...
  }: let
    lib = import ./lib {
      nixpkgs = inputs.inputs.nixpkgs;
      inputs = inputs.inputs;
      inherit self;
    };
    inherit (lib) findModules buildHosts buildOizys;
  in {
    nixosModules = findModules {};
    nixosConfigurations = buildHosts {};
    packages = buildOizys {};
  };
}
