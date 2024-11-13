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
  nimbleDepsHash = "sha256-J/iuDYR5A771zAuRKA94rwXX9L3+KtiodDxQRFO0GEc=";

  meta = {
    description = "nix begat oizys";
  };
}
