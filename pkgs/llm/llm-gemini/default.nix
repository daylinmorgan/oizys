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

buildPythonPackage rec {
  pname = "llm-gemini";
  version = "0.10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-gemini";
    rev = version;
    hash = "sha256-+ghsBvEY8GQAphdvG7Rdu3T/7yz64vmkuA1VGvqw1fU=";
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
