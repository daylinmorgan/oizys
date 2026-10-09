{
  lib,
  substituters ? null,

  nix-eval-jobs,

  installShellFiles,
  makeWrapper,
  rustPlatform,
  ...
}:

let
  inherit (builtins) readFile fromTOML getAttr;
  version =
    ./Cargo.toml
    |> readFile
    |> fromTOML
    |> getAttr "package"
    |> getAttr "version";
in
rustPlatform.buildRustPackage (
  finalAttrs:
  {

    pname = "oizys";
    src =  lib.cleanSource ./.;
    version = "${version}-unstable";
    nativeBuildInputs = [
      makeWrapper
      installShellFiles
    ];
    doCheck = false; # unit tests are for the weak

    postInstall = ''
      wrapProgram $out/bin/oizys \
        --prefix PATH : ${
          lib.makeBinPath [
            nix-eval-jobs
          ]
        }

      installShellCompletion --cmd oizys \
        --zsh <($out/bin/oizys completion zsh)
    '';
    cargoHash = "sha256-u+M8NqBfErwhRQfJjUOI/yh8MX6MUgSTUIwTv3UP5co=";
  }
  // (lib.optionalAttrs (substituters != null) {
    postConfigure = "echo '${builtins.toJSON substituters}' >> src/substituters.json";
    # buildFeatures = [ "substituters" ];
    cargoExtraArgs = "--features substituters";
  })

)
