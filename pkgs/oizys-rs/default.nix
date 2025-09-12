{
  pkgs,
  lib,
  crane,
  substituters ? null,

  openssl,
  pkg-config,

  jq,
  nix-eval-jobs,

  installShellFiles,
  makeWrapper,
}:

let
  inherit (builtins) readFile fromTOML getAttr;
  version = ./Cargo.toml |> readFile |> fromTOML |> getAttr "package" |> getAttr "version";
  craneLib = crane.mkLib pkgs;
  commonArgs = {
    pname = "oizys-rs";
    src = lib.cleanSource ./.;
    # src = craneLib.cleanCargoSource ./.;
    buildInputs = [ openssl ];
  };
  nativeBuildInputs = [ pkg-config ];
  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      inherit nativeBuildInputs;
    }
  );
in

craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;
    version = "${version}-unstable";
    nativeBuildInputs = nativeBuildInputs ++ [
      makeWrapper
      installShellFiles
    ];
    doCheck = false; # unit tests are for the weak

    postInstall = ''
      wrapProgram $out/bin/oizys-rs \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          nix-eval-jobs
        ]
      }

      installShellCompletion --cmd oizys-rs \
      --zsh <($out/bin/oizys-rs completion zsh)
    '';

  }
  // (lib.optionalAttrs (substituters != null) {
    postConfigure = "echo '${builtins.toJSON substituters}' >> src/substituters.json";
    # buildFeatures = [ "substituters" ];
    cargoExtraArgs = "--features substituters";
  })
)
