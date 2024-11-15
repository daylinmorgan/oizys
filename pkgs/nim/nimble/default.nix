{
  fetchFromGitHub,
  buildNimPackage,
  # deps
  openssl,

}:
buildNimPackage (finalAttrs: {
  pname = "nimble";
  version = "0.16.3";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1tO/6sKPjmu9B6/cF00DeY/mnUHi2Y+hTEZ3WCqKoGw=";
    fetchSubmodules = true;
  };
  buildInputs = [ openssl ];
  doCheck = false;

  # localPassC needed from zippy since name mangling on nix is broken
  nimFlags = [
    ''--passC:"-msse4.1 -mpclmul"''
  ];
})
