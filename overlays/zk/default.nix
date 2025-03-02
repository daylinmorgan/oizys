{ ... }:
final: prev: {
  zk = prev.zk.overrideAttrs (
    finalAttrs: _: {
      version = "0.14.2-unstable";

      src = prev.fetchFromGitHub {
        owner = "zk-org";
        repo = "zk";
        rev = "64ad7f4087d51b04751baddcc64a8a0c1986f4e3";
        sha256 = "sha256-WEKtXnOLrNjmLFqtPBrwd1O/PsysmveDI//LlSObp5Y=";
      };
    }
  );
}
