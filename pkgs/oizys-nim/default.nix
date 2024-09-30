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
  nimbleDepsHash = "sha256-3p+PdGkQmKwz5tzJwX0aun3kSOLw/lwzqRkR9+6ECQE=";
}
