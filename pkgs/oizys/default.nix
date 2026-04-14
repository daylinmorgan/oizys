{
  lib,
  openssl,
  buildAtlasPackage,

  substituters ? [ ],
  trusted-public-keys ? [ ],
}:

let
  subFlag = toString substituters;
  trustedPubKeys = toString trusted-public-keys;
in

buildAtlasPackage {
  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  atlasDepsHash = "sha256-d864CU8Vi+2fKqQgbuQqgOBgshJL1S5yWlGuKutG+A8=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
