{ version, hash }:
{
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  wheel,

  # deps
  httpx,
  ijson,
  ...
}:

buildPythonPackage {
  inherit version;
  pname = "llm-gemini";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-gemini";
    rev = version;
    inherit hash;
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [
    httpx
    ijson
  ];

  dontCheckRuntimeDeps = true;
}
