{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
}:

buildNimPackage (
  final: prev: {
    pname = "atlas";
    version = "unstable-2026-01-05";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = "atlas";
      rev = "e812aa1350dc9ee95ec357664d5a01311efd6bbd";
      hash = "sha256-TCqhyUZg8DLsZoy3JXIJwg7u1B21ZZyPtAIa+PMYqs8=";
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
