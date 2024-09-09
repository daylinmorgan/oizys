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
  nimbleDepsHash = "sha256-WeTbNoF+TuzWriqoHWk5DBVgBXtNBIBHMkwy8/+a2JA=";
}
