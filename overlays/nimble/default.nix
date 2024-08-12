{ ... }:
(final: prev: {
  nimble = prev.nimble.overrideNimAttrs rec {
    version = "0.16.0";
    requiredNimVersion = 2;
    buildInputs = [ prev.pkgs.openssl ];

    src = final.fetchFromGitHub {
      owner = "nim-lang";
      repo = "nimble";
      rev = "v${version}";
      hash = "sha256-nsQAUe+soRkWAFPYP5LftBCvQdkC1SpiIORscDsPQB4=";
    };
  };
})
