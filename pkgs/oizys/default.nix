{
  lib,
  openssl,
  buildNimblePackage,

  substituters ? [ ],
  trusted-public-keys ? [ ],
}:

let
  inherit (builtins) toString;
  subFlag = toString substituters;
  trustedPubKeys = toString trusted-public-keys;
in

buildNimblePackage {
  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-M9BG5Vh4mcMRLUlv/kPIyuPl52henVXsx7gPlCrR7O8=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
