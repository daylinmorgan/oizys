{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.6.0";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    # rev = "26b333d0c8d62ba947a9ce9fbd59a7a77766872c";
    rev = "v${finalAttrs.version}";
    hash = "sha256-rTlkbNuJbL9ke1FpHYVYduiYHUON6oACg20pBs0MaP4=";
  };

  doCheck = false;
  lockFile = ./lock.json;
})
