{
  lib,
  openssl,
  buildNimblePackage,
}:
buildNimblePackage {
  name = "oizys";
  verions = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-n+K5hFiS1tEy2jDAoAoSgE75TCiqZK+al/0Mfc1d4kI=";
}
