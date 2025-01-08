{
  fetchFromGitHub,
  buildNimPackage,
  nim-2_0,
}:
let
  buildNimPackage' = buildNimPackage.override {
    # Do not build with Nim-2.2.x.
    nim2 = nim-2_0;
  };
in
buildNimPackage' (finalAttrs: {
  pname = "nph";
  version = "0.6.1";
  src = fetchFromGitHub {
    owner = "arnetheduck";
    repo = "nph";
    rev = "v${finalAttrs.version}";
    hash = "sha256-RIuggg09l7jZDg91FPrjwdoE+gCxgb7c8fEvCiwQk5U=";
  };
  # replace gorge(git...) call to for version
  patchPhase = ''
    runHook prePatch
    sed -i 's/Version = gorge(.*/Version = """v${finalAttrs.version}\n"""/' src/nph.nim
    runHook postPatch
  '';
  doCheck = false;
})
