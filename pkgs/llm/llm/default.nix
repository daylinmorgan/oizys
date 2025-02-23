{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  setuptools,

  # deps
  click-default-group,
  numpy,
  openai,
  pip,
  pluggy,
  pydantic,
  python-ulid,
  pyyaml,
  sqlite-migrate,
  cogapp,
  pytest-httpx,
  puremagic,
  sqlite-utils,

  pytestCheckHook,
}:
  buildPythonPackage rec {
    pname = "llm";
    version = "0.22";
    pyproject = true;

    build-system = [ setuptools ];

    disabled = pythonOlder "3.8";

    src = fetchFromGitHub {
      owner = "simonw";
      repo = "llm";
      rev = "refs/tags/${version}";
      hash = "sha256-l4tFBCIey5cOUvJ8IXLOjslc1zy9MnuiwFFP275S/Bg=";
    };

    # patches = [ ./001-disable-install-uninstall-commands.patch ];

    dependencies = [
      click-default-group
      numpy
      openai
      pip
      pluggy
      pydantic
      python-ulid
      pyyaml
      setuptools # for pkg_resources
      sqlite-migrate
      sqlite-utils
      puremagic
    ];

    nativeCheckInputs = [
      cogapp
      numpy
      pytest-httpx
      pytestCheckHook
    ];

    doCheck = true;

    pytestFlagsArray = [
      "-svv"
      "tests/"
    ];

    pythonImportsCheck = [ "llm" ];

    meta = with lib; {
      homepage = "https://github.com/simonw/llm";
      description = "Access large language models from the command-line";
      changelog = "https://github.com/simonw/llm/releases/tag/${version}";
      license = licenses.asl20;
      mainProgram = "llm";
      maintainers = with maintainers; [
        aldoborrero
        mccartykim
      ];
    };
  }
