{ version, hash }:
{
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  wheel,

  ...
}:

buildPythonPackage {
  inherit version;
  pname = "llm-jq";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-jq";
    rev = version;
    inherit hash;

  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dontCheckRuntimeDeps = true;
}
