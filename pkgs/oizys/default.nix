{
  lib,
  openssl,
  buildNimblePackage,

  nix-eval-jobs,
  makeWrapper,
}:

buildNimblePackage {

  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl makeWrapper ];
  nimbleDepsHash = "sha256-bthmRlUO6IOYRiwVic0TPOvo0gsfD/49J2GzoIQqlF0=";
  meta = {
    description = "nix begat oizys";
  };

  postFixup = ''
    wrapProgram $out/bin/oizys \
        --set PATH ${
          lib.makeBinPath [
            nix-eval-jobs
          ]
        }
  '';

}
