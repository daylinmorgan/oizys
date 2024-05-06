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
  vendorHash = "sha256-Fcq8p/YItF5lx82PRg1/tksV7iCIS0xZZVWdpE3e7F0=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys completion zsh)
  '';
}
