{
  lib,
  buildNimPackage,
  fetchFromGitHub,
}:
buildNimPackage (final: prev: {
  pname = "styx";
  version = "2023.1001";
  src = ./.;
  lockFile = ./lock.json;
})
