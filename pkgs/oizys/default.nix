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
  nimbleDepsHash = "sha256-1YoGvWvoJJSMauDbeH8ZHuK+QQot48Mkye9TeWteT8k=";

  meta = {
    description = "nix begat oizys";
  };
}
