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
  nimbleDepsHash = "sha256-A2sQy4x+QyqltV7B1rRh7uRPvv7pDtVNOXZZl5LrHCY=";
}
