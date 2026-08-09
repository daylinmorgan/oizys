inputs: final: prev:
let
  version = "0.70.0";
in
{
  difftastic = prev.difftastic.overrideAttrs (
    finalAttrs: _: {
      inherit version;
      src = final.fetchFromGitHub {
        owner = "daylinmorgan";
        repo = "difftastic";
        rev = "${version}-nim"; # finalAttrs.version;
        hash = "sha256-jRdzJhjouE7kjh4ieNOpR5+MulceSMnRtiVPVxF471U=";
      };
      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = "${finalAttrs.src}/Cargo.lock";
      };
    }
  );
}
