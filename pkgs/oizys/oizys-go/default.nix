{
  self,
  lib,
  installShellFiles,
  buildGoModule,
  makeWrapper,
  gh,
  nix-output-monitor,
  ...
}:
let
  inherit (lib) mkDate cleanSource makeBinPath;
in
buildGoModule {
  pname = "oizys";
  version = "d${mkDate self.lastModifiedDate}";

  src = cleanSource ./.;
  vendorHash = "sha256-/JVXhXrU2np/ty7AGFy+LPZCo1NaLYl9NAyD9+FJYBI=";

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
      --prefix PATH ':' ${
        makeBinPath [
          gh
          nix-output-monitor
        ]
      }
  '';
}
