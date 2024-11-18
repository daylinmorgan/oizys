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
  nimbleDepsHash = "sha256-1AztepAkNtxC3lfi5gTj1QrhejKNsNXa4mUdR958vJM=";

  meta = {
    description = "nix begat oizys";
  };
}
