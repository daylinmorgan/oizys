{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.10.2-unstable";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    # rev = "v${finalAttrs.version}";
    rev = "380e4634f2891a926e40c334161931676b074b5a";
    hash = "sha256-Tx/2aA5q2K44E2tSlbZNwubJDHV9V+8EDFwR5c0Gjn8=";
  };

  doCheck = false;

  # nix build '.#nimlangserver.src'
  # nix run "github:daylinmorgan/nnl" -- result/nimble.lock -o:pkgs/nim/nimlangserver/lock.json --prefetch-git:bearssl,zlib
  lockFile = ./lock.json;
})
