{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.8.0";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    rev = "v${finalAttrs.version}";
    hash = "sha256-JyBjHAP/sxQfQ1XvyeZyHsu0Er5D7ePDGyJK7Do5kyk=";
  };

  doCheck = false;

  # nix build '.#nimlangserver.src'
  # nix run "github:daylinmorgan/nnl" -- result/nimble.lock -o:pkgs/nim/nimlangserver/lock.json --prefetch-git:bearssl,zlib
  lockFile = ./lock.json;
})
