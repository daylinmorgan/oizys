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

buildPythonPackage rec {
  pname = "llm-cmd";
  version = "0.2a0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-cmd";
    rev = version;
    hash = "sha256-RhwQEllpee/XP1p0nrgL4m+KjSZzf61J8l1jJGlg94E=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [
    prompt_toolkit pygments
  ];

  dontCheckRuntimeDeps = true;
}
