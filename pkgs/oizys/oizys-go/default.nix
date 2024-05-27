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
  vendorHash = "sha256-NCHU491j6fRfSk6LA9tS9yiuT/gZhPic46mNTVf1Jeg=";

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
