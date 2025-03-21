{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    rev = "v${finalAttrs.version}";
    hash = "sha256-KApIzGknWDb7UJkzii9rGOING4G8D31zUoWvMH4iw4A=";
  };

  doCheck = false;

  # nix build '.#nimlangserver.src'
  # nix run "github:daylinmorgan/nnl" -- result/nimble.lock -o:pkgs/nim/nimlangserver/lock.json --prefetch-git:bearssl,zlib
  lockFile = ./lock.json;
})
