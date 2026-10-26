{
  inputs,
  pkgs,
  lib,
  substituters ? null,

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
  craneLib = inputs.crane.mkLib pkgs;
in
craneLib.buildPackage {

  pname = "oizys";
  src = lib.cleanSource ./.;
  version = "${version}-unstable";
  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];
  doCheck = false; # unit tests are for the weak
  env = {
    OIZYS_HOSTS = hosts;
  }
  // lib.optionalAttrs (substituters != null) {
    OIZYS_SUBSTITUTERS = builtins.toJSON substituters;
  };
  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys completion zsh)
  '';
  # cargoHash = "sha256-Al3UEl4gHMVmg9j/JyXsS/cb08GKTVAZBfVgj3P+D5o=";
}
