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
  # TODO: get hosts also
  inherit (builtins)
    readFile
    getAttr
    concatStringsSep
    readDir
    attrNames
    ;
  hosts =
    ../../hosts
    |> readDir
    |> attrNames
    |> concatStringsSep ",";
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
    src = lib.cleanSource ./.;
    version = "${version}-unstable";
    nativeBuildInputs = [
      makeWrapper
      installShellFiles
    ];
    doCheck = false; # unit tests are for the weak
    env.OIZYS_HOSTS = hosts;
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
    cargoHash = "sha256-EnhuhPYjU/ml1Had/TiYvBUq6ODIXxgQOka+014cyB8=";
  }
  // (lib.optionalAttrs (substituters != null) {
    postConfigure = "echo '${builtins.toJSON substituters}' >> src/substituters.json";
    buildFeatures = [ "substituters" ];
  })

)
