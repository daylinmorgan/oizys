{ ... }:
(final: prev: {
  nimble = prev.nimble.overrideNimAttrs {
    version = "0.14.2-5e7901760e89108476a4e21976a0ef783403e8fe";
    requiredNimVersion = 2;
    buildInputs = [ prev.pkgs.openssl ];

    src = final.fetchFromGitHub {
      owner = "nim-lang";
      repo = "nimble";

      # most recent commit 2024-03-11
      rev = "5e7901760e89108476a4e21976a0ef783403e8fe";
      hash = "sha256-8b5yKvEl7c7wA/8cpdaN2CSvawQJzuRce6mULj3z/mI=";
    };
  };
})
