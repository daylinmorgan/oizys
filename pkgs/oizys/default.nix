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
  nimbleDepsHash = "sha256-ZEPzosRwokkvPKbv5nqzATv6IqUhqM2prOU0vUUC80Q=";

  meta = {
    description = "nix begat oizys";
  };
}
