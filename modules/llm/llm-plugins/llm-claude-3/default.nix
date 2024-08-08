{
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  wheel,

  # deps
  anthropic,
  ...
}:

buildPythonPackage rec {
  pname = "llm-claude-3";
  version = "0.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-claude-3";
    rev = version;
    hash = "sha256-5qF5BK319PNzB4XsLdYvtyq/SxBDdHJ9IoKWEnvNRp4=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [ anthropic ];

  dontCheckRuntimeDeps = true;
}
