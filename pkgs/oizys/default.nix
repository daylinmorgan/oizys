{
  lib,
  openssl,
  buildAtlasPackage,

  substituters ? [ ],
  trusted-public-keys ? [ ],
}:

let
  inherit (builtins) concatStringsSep readDir attrNames;
  subFlag = toString substituters;
  trustedPubKeys = toString trusted-public-keys;
  hosts =
    ../../hosts
    |> readDir
    |> attrNames
    |> concatStringsSep ",";
in

buildAtlasPackage {
  name = "oizys";
  version = "unstable";

  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  atlasDepsHash = "sha256-u84fQCSbuoDE/s2wDEitxTnSHK2kw4o+VL3rSE0Lc8I=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
    "-d:hosts:${hosts}"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
