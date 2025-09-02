{
  lib,
  rustPlatform,
  substituters ? null,

  openssl,
  pkg-config,

  installShellFiles,
}:

let
  inherit (builtins) readFile fromTOML getAttr;
  version = ./Cargo.toml |> readFile |> fromTOML |> getAttr "package" |> getAttr "version";
in

rustPlatform.buildRustPackage (
  finalAttrs:
  {
    name = "oizys-rs";
    version = "${version}-unstable";
    src = ./.;
    cargoHash = "sha256-FPaHicPOjgN9iRPGReYBS7Sr2ZjGtE3LgiZ8hGIev/0=";
    nativeBuildInputs = [
      installShellFiles
      pkg-config
    ];
    buildInputs = [
      openssl
    ];
    doCheck = false; # unit tests are for the weak

    postInstall = ''
      installShellCompletion --cmd oizys-rs \
      --zsh <($out/bin/oizys-rs completion zsh)
    '';

  }
  // (lib.optionalAttrs (substituters != null) {

    postConfigure = "echo '${builtins.toJSON substituters}' >> src/substituters.json";
    buildFeatures = [ "substituters" ];
  })
)
