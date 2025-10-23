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
  atlasDepsHash = "sha256-3e8Rk7gTBWSgFBWPUay557vu/C9OhYcFvL9R86Q0nk8=";
  nimFlags = [
    "-d:substituters:\"${subFlag}\""
    "-d:trustedPublicKeys:'${trustedPubKeys}'"
  ];
  meta = {
    description = "nix begat oizys";
  };

}
