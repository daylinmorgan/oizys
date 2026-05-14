{
  fetchFromGitHub,
  buildNimPackage,
  nim-nnl-update-script,
}:
buildNimPackage (finalAttrs: {
  pname = "procs";
  version = "0.8.13";
  src = fetchFromGitHub {
    owner = "c-blake";
    repo = "procs";
    rev = finalAttrs.version;
    hash = "sha256-Mk6mvk00V/Yjr6DaN+Rj2Eqhs7vZ6l345S4rN0+aGF8=";
  };

  doCheck = false;
  lockFile = ./lock.json;

  passthru.updateScript = nim-nnl-update-script { };
})
