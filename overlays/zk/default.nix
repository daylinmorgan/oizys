{ ... }:
final: prev: {
  zk = prev.zk.overrideAttrs (
    finalAttrs: _: {
      version = "0.14.2-pr526";

      src = prev.fetchFromGitHub {
        owner = "gyorb";
        repo = "zk";
        rev = "fix-ctrl-e";
        sha256 = "sha256-NL9CgzB/VNONCmpz7RzrteQDKK0Y/PYAfwxqYjFoIrY=";
      };

    }
  );

}
