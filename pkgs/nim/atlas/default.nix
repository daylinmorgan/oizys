{
  lib,
  buildNimPackage,
  fetchFromGitHub,
  openssl,
  nim-nnl-update-script,
}:

buildNimPackage (finalAttrs: {
  pname = "atlas";
  version = "0.14.5";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "atlas";
    rev = finalAttrs.version;
    hash = "sha256-VT8hVKWRtWWSigaErdGS20tYdBD3f4WP755OphH9DjA=";
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
