inputs: final: prev: {
  difftastic = prev.difftastic.overrideAttrs (
    finalAttrs: _: {
      version = "0.69.0"; # 0.69.0-nim, really
      src = final.fetchFromGitHub {
        owner = "daylinmorgan";
        repo = "difftastic";
        rev = "0.69.0-nim"; # finalAttrs.version;
        hash = "sha256-H7hmteydc7zlPjTXfH5mqEYZEfC0W4S7+unOi0a4kz8=";
      };
      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = "${finalAttrs.src}/Cargo.lock";
      };
    }
  );
}
