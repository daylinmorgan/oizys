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
  vendorHash = "sha256-Geqcp0/7I1IF2IfaYyIChz7SOCF+elIEdcz2VsAU0hQ=";

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
