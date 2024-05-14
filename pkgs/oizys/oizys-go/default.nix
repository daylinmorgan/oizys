{
  installShellFiles,
  buildGoModule,
  lib,
  ...
}:
buildGoModule {
  pname = "oizys";
  version = "unstable";

  src = lib.cleanSource ./.;
  vendorHash = "sha256-NCHU491j6fRfSk6LA9tS9yiuT/gZhPic46mNTVf1Jeg=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys completion zsh)
  '';
}
