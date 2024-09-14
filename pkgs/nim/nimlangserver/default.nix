{ fetchFromGitHub, buildNimPackage }:
buildNimPackage{
  pname = "nimlangserver";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "daylinmorgan";
    repo = "langserver";
    rev = "26b333d0c8d62ba947a9ce9fbd59a7a77766872c";
    # rev = "v${version}";
    hash = "sha256-XFgA0yOfE34+bZxBgOdoK+5CWhxvppzl8QSQx1TTPpQ=";
  };

  doCheck = false;
  lockFile = ./lock.json;
}
