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
  pname = "llm-python";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-python";
    rev = version;
    inherit hash;
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [ ];

  dontCheckRuntimeDeps = true;
}
