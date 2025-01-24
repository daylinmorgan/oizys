{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.8.1";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    rev = "v${finalAttrs.version}";
    hash = "sha256-j5YnTGPtt0WhRvNfpgO9tjAqZJA5Kt1FE1Mjqn0/DNY=";
  };

  doCheck = false;

  # nix build '.#nimlangserver.src'
  # nix run "github:daylinmorgan/nnl" -- result/nimble.lock -o:pkgs/nim/nimlangserver/lock.json --prefetch-git:bearssl,zlib
  lockFile = ./lock.json;
})
