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
  nimbleDepsHash = "sha256-Eheeve4MbB3v1oVj0mB36Mv2Q3vJGLEbbShds1af23g=";
}
