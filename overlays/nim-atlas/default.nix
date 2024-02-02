{...}: (final: prev: {
  nim-atlas = prev.nim-atlas.overrideNimAttrs {
    version = "unstable";
    src = final.fetchFromGitHub {
      owner = "nim-lang";
      repo = "atlas";
      rev = "cbba9fa77fa837931bf3c58e20c1f8cb15a22919";
      hash = "sha256-TsZ8TriVuKEY9/mV6KR89eFOgYrgTqXmyv/vKu362GU=";
    };
  };
})
