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
  nimbleDepsHash = "sha256-o+CN0LlVOcgjLpDfjItW/5GCXTWcPSx9GfwQn+u2ST4=";
}
