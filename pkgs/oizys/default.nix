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
  nimbleDepsHash = "sha256-0F/rKcLUH95vW3ODB2mgMQ2klbN9rjMeP+LUK0Ucj2w=";

  meta = {
    description = "nix begat oizys";
  };
}
