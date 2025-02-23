{
  version,
  hash,
}:

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

buildPythonPackage {
  inherit version;
  pname = "llm-anthropic";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-anthropic";
    rev = version;
    inherit hash;
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dependencies = [ anthropic ];

  dontCheckRuntimeDeps = true;
}
