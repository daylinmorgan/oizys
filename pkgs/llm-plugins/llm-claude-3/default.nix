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
  version = "0.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-claude-3";
    rev = version;
    hash = "sha256-XhmxUo+nM6el17AVRUq+RLT5SEl+Q0eWhouU9WDZJl0=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [ anthropic ];

  dontCheckRuntimeDeps = true;
}
