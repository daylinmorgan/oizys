{
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  setuptools,
  wheel,

  ...
}:

buildPythonPackage rec {
  pname = "llm-jq";
  version = "0.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "llm-jq";
    rev = version;
    hash = "sha256-Mf/tbB9+UdmSRpulqv5Wagr8wjDcRrNs2741DNQZhO4=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  dontCheckRuntimeDeps = true;
}
