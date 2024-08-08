{
  buildPythonPackage,
  fetchPypi,

  # build-system
  setuptools,

  # deps
  ollama,
  pydantic,

  ...
}:
buildPythonPackage rec {
  pname = "llm-ollama";
  version = "0.5.0";
  pyproject = true;
  src = fetchPypi {
    inherit version;
    pname = "llm_ollama";
    hash = "sha256-M3FF9fAZ2rr+toKoz/rLRPZxB7LIHqmZQXJBdKR4fVk=";
  };

  dependencies = [
    ollama
    pydantic
  ];

  build-system = [ setuptools ];

  # will only be used in environment with llm installed
  dontCheckRuntimeDeps = true;
}
