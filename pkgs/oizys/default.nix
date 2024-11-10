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
  nimbleDepsHash = "sha256-/H/HvnJqpDJcyVJ2rbn7PDSSoJB/TMr9yiIKxtB1O+E=";

  meta = {
    description = "nix begat oizys";
  };
}
