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
  pname = "llm-anthropic";
  version = "0.12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-anthropic";
    rev = version;
    hash = "sha256-7+5j5jZBFfaaqnfjvLTI+mz1PUuG8sB5nD59UCpJuR4=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [ anthropic ];

  dontCheckRuntimeDeps = true;
}
