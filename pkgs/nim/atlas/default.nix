{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
  nim-nnl-update-script,
}:

buildNimPackage (finalAttrs: {
  pname = "atlas";
  version = "0.14.2";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "atlas";
    rev = finalAttrs.version;
    hash = "sha256-flQo4PeIcWEZn2uBJ6b3Uol0nvTXNU39bK5KsK6KwfU=";
  };
  lockFile = ./lock.json;
  buildInputs = [ openssl ];
  doCheck = false; # tests will clone repos
  passthru.updateScript = nim-nnl-update-script { };
  meta = finalAttrs.src.meta // {
    description = "Nim package cloner";
    mainProgram = "atlas";
    license = [ lib.licenses.mit ];
  };
})
