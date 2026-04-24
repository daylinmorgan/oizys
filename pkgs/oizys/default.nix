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

  # this is necessary to allow the hosts to be discovered at compile time
  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.unions [
      (lib.fileset.fromSource (lib.cleanSource ./.))
      ../../hosts
    ];
  };
  sourceRoot = "source/pkgs/oizys";
  nativeBuildInputs = [ openssl ];
  atlasDepsHash = "sha256-rk/m87uar0Aa7HxhpQu7rNFlaOMqp4ITtPSI3wU92TY=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
