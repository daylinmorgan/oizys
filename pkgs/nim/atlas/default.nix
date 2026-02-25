{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
}:

buildNimPackage (
  final: prev: {
    pname = "atlas";
    version = "0.10.1";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = "atlas";
      rev = final.version;
      hash = "sha256-WUnPvwsZ0IiDU3WhOQBUf2zT47jUFkZ0Kxn4oxWqdSU=";
    };
    lockFile = ./lock.json;
    buildInputs = [ openssl ];
    doCheck = false; # tests will clone repos
    meta = final.src.meta // {
      description = "Nim package cloner";
      mainProgram = "atlas";
      license = [ lib.licenses.mit ];
    };
  }
)
