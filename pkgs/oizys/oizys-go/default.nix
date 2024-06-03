{
  lib,
  installShellFiles,
  buildGoModule,
  makeWrapper,
  gh,
  ...
}:
buildGoModule {
  pname = "oizys";
  version = "unstable";

  src = lib.cleanSource ./.;
  vendorHash = "sha256-9dfEWPq4dVksv7b2TobnWUc3MwMnKEA40UVTDOSDREg=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <(OIZYS_SKIP_CHECK=true $out/bin/oizys completion zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/oizys \
      --prefix PATH ${lib.makeBinPath [ gh ]}
  '';
}
