{
  lib,
  buildNimPackage,
}:
buildNimPackage (final: prev: {
  pname = "oizys";
  version = "unstable";
  src = ./.;
})
