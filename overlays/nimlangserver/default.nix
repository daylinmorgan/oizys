{ ... }:
(final: prev: {
  nimlangserver = prev.nimlangserver.overrideNimAttrs rec {
    version = "1.4.0";

    lockFile = ./lock.json;
    src = final.fetchFromGitHub {
      owner = "nim-lang";
      repo = "langserver";
      rev = "v${version}";
      hash = "sha256-mh+p8t8/mbZvgsJ930lXkcBdUjjioZoNyNZzwywAiUI=";
    };
  };
})
