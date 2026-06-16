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
  atlasDepsHash = "sha256-hw0jrtp0CY5T00Tt3BgLQ5z12FH6/ITaFVrPYxBSbfE=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
    "-d:hosts:${hosts}"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
