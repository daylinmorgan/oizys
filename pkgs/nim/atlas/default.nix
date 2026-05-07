{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
}:

buildNimPackage (
  final: prev: {
    pname = "atlas";
    version = "0.12.2";
    src = fetchFromGitHub {
      owner = "nim-lang";
      repo = "atlas";
      rev = "fb0c7753cacafcde49fb46571d58c7883c3a270f";
      hash = "sha256-yePTzKkcG4onh886NJCPz0XEfdK4shJ3baLVmmQwJPU=";
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
