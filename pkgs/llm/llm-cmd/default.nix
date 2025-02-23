{ version, hash }:
{
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  wheel,

  # deps
  prompt_toolkit,
  pygments,
  ...
}:

buildPythonPackage {
  inherit version;
  pname = "llm-cmd";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-cmd";
    rev = version;
    inherit hash;
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [
    prompt_toolkit
    pygments
  ];

  dontCheckRuntimeDeps = true;
}
