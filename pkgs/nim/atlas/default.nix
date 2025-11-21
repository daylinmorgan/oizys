{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
}:

buildNimPackage (
  final: prev: {
    pname = "atlas";
    version = "unstable-2025-11-06";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = "atlas";
      rev = "5ffc041c1c529d7d4083e2694bd093f80d03d901";
      hash = "sha256-sngWtS3ZDJzBtQaWma1ro3hRbmGZFyzHGRkvoGNaiKU=";
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
