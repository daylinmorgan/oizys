{
  fetchFromGitHub,
  buildNimPackage,
  # deps
  openssl,

}:
buildNimPackage (finalAttrs: {
  pname = "nimble";
  version = "0.16.1";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "v${finalAttrs.version}";
    hash = "sha256-sa0irAZjQRZLduEMBPf7sHlY1FigBJTR/vIH4ihii/w=";
  };
  buildInputs = [ openssl ];
  lockFile = ./lock.json;
  doCheck = false;
})
