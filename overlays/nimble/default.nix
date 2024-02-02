{...}: (final: prev: {
  nimble = prev.nimble.overrideNimAttrs {
    version = "0.14.2-f74bf2";
    requiredNimVersion = 2;
    buildInputs = [prev.pkgs.openssl];

    src = final.fetchFromGitHub {
      owner = "nim-lang";
      repo = "nimble";
      # more recent commit
      rev = "f74bf2bc388f7a0154104b4bcaa093a499d3f0f7";
      hash = "sha256-8b5yKvEl7c7wA/8cpdaN2CSvawQJzuRce6mULj3z/mI=";
    };
  };
})
