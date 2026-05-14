{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
  nim-nnl-update-script,
}:

buildNimPackage (finalAttrs: {
  pname = "atlas";
  version = "0.12.5";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "atlas";
    rev = finalAttrs.version;
    hash = "sha256-5ffpUVb7crbZUkHY17tY99qATGATNr8VNz5AhIyJ8Xc=";
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
