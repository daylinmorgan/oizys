{
  lib,
  openssl,
  buildNimblePackage,
}:

buildNimblePackage {

  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl];
  nimbleDepsHash = "sha256-ZNS/ak5UoH3cvOAnRdCoovo/20A8woxowa5wefluU5g=";
  meta = {
    description = "nix begat oizys";
  };

}
