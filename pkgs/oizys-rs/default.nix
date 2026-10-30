{
  inputs,
  pkgs,
  lib,
  substituters ? null,

  installShellFiles,
  makeWrapper,
  ...
}:

let
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
}
