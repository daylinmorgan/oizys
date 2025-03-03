{
  lib,
  openssl,
  buildNimblePackage,

  extra-substituters ? [ ],
  extra-trusted-public-keys ? [ ],
}:

let
  inherit (builtins) toString;
  extraSubFlag = toString extra-substituters;
  extraTrustedPubKeys = toString extra-trusted-public-keys;
in

buildNimblePackage {

  name = "oizys";
  version = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-ZNS/ak5UoH3cvOAnRdCoovo/20A8woxowa5wefluU5g=";
  nimFlags = [
    "-d:extraSubstituters:\"${extraSubFlag}\""
    "-d:extraTrustedPublicKeys:'${extraTrustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
