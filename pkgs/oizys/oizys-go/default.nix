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
  vendorHash = "sha256-kh/7dV49KaQcD9ho8IpBcRc6+05bn4XpMzAI9JXu7+o=";

  nativeBuildInputs = [installShellFiles];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys completion zsh)
  '';
}
