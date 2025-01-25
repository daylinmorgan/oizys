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
  nimbleDepsHash = "sha256-wuTGoswuAxAOOPDDI6Ma8Xzq1CApCfT+fAQmJg+VeYM=";
  meta = {
    description = "nix begat oizys";
  };
}
