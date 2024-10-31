{
  fetchFromGitHub,
  buildNimPackage,
  # deps
  openssl,

}:
buildNimPackage (finalAttrs: {
  pname = "nimble";
  version = "0.16.2";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "v${finalAttrs.version}";
    hash = "sha256-MVHf19UbOWk8Zba2scj06PxdYYOJA6OXrVyDQ9Ku6Us=";
  };
  buildInputs = [ openssl ];
  lockFile = ./lock.json;
  doCheck = false;
})
