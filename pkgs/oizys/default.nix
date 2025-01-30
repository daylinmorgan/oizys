{
  lib,
  openssl,
  buildNimblePackage,
}:
buildNimblePackage {
  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-DE5PAgcntxMwmgd7NnabYhOBH5szSvwPM9sNdnF/Iyc=";
  meta = {
    description = "nix begat oizys";
  };
}
