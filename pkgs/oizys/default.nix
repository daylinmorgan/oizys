{
  lib,
  openssl,
  buildAtlasPackage,

  substituters ? [ ],
  trusted-public-keys ? [ ],
}:

let
  inherit (builtins) toString;
  subFlag = toString substituters;
  trustedPubKeys = toString trusted-public-keys;
in

buildAtlasPackage {
  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  atlasDepsHash = "sha256-dW6HjOgP4mMb1KATbUiQSMRFiIte+AnA7liieWuBeJc=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
