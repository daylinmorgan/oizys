{
  lib,
  installShellFiles,
  buildGoModule,
  makeWrapper,
  ...
}:
let
  inherit (lib) cleanSource;
in
buildGoModule {
  pname = "oizys";
  version = "unstable";

  src = cleanSource ./.;
  vendorHash = "sha256-+4OtpcKHfomBAXRrJOvkhQdCSwU0W6+5OJuS4o12r5E=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <(OIZYS_SKIP_CHECK=true $out/bin/oizys completion zsh)
  '';

}
