inputs: final: prev:
{
  difftastic = prev.difftastic.overrideAttrs (
    finalAttrs: _: {
      version = "0.69.0"; # 0.68.0-nim, really
      src = final.fetchFromGitHub {
        owner = "daylinmorgan";
        repo = "difftastic";
        rev = "0.68.0-nim"; # finalAttrs.version;
        hash = "sha256-v5VE8Hl1FS6ynOrmqUjezII9CB8acKDyGNDfOh1E06Q=";
      };
      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = "${finalAttrs.src}/Cargo.lock";
      };
    }
  );
}
