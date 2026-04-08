{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (_finalAttrs: {
  pname = "nimlangserver";
  version = "1.12.0-unstable";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    # rev = "v${finalAttrs.version}";
    rev = "aa4be4cbae932d3fbb5c5b3b28e70c2df6e7f426";
    hash = "sha256-py7XSZRDh10dv/S9rtyP71XauyTZC268afZ+XKQfWlo=";
  };

  doCheck = false;

  # nix build '.#nimlangserver.src'
  # nix run "github:daylinmorgan/nnl" -- result/nimble.lock -o:pkgs/nim/nimlangserver/lock.json --git,=bearssl,zlib
  lockFile = ./lock.json;
})
