{
  lib,
  openssl,
  buildNimblePackage,
}:
buildNimblePackage {
  name = "oizys";
  verions = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-YCHyMyy6cvNZgsmxPgskbAMETHs4/bP2Cp6XbjfWm1k=";

  meta = {
    description = "nix begat oizys";
  };
}
