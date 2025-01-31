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
  nimbleDepsHash = "sha256-bthmRlUO6IOYRiwVic0TPOvo0gsfD/49J2GzoIQqlF0=";
  meta = {
    description = "nix begat oizys";
  };
}
