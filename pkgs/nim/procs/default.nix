{
  fetchFromGitHub,
  buildNimPackage,
  nim-nnl-update-script,
}:
buildNimPackage (finalAttrs: {
  pname = "procs";
  version = "0.7.3";
  src = fetchFromGitHub {
    owner = "c-blake";
    repo = "procs";
    rev = finalAttrs.version;
    hash = "sha256-TlR3eOPI6ed0EbGUdSdDYaYKippiFOspSWkv2JePR4M=";
  };

  doCheck = false;
  lockFile = ./lock.json;

  passthru.updateScript = nim-nnl-update-script {
    inherit (finalAttrs) pname version src;
  };
})
