{
  lib,
  openssl,
  buildNimblePackage,
}:
buildNimblePackage {
  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-2xuTo85qPZtcNGlcD5/SXkRN73srbTBVtiPtFYmq2Ww=";

  meta = {
    description = "nix begat oizys";
  };
}
