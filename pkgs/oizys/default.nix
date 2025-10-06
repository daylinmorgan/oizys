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
  nimbleDepsHash = "sha256-nc5tP6GB1uNBHfvzeYorY/tKAVFHKzoleC7pQv7dPzw=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
