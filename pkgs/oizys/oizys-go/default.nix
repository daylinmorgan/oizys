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
mkDate =
    longDate:
    (lib.concatStringsSep "-" [
      (builtins.substring 0 4 longDate)
      (builtins.substring 4 2 longDate)
      (builtins.substring 6 2 longDate)
    ]);
in
buildGoModule {
  pname = "oizys";
  version = "date=${mkDate self.lastModifiedDate}";

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
      --prefix PATH ':' ${lib.makeBinPath [ gh nix-output-monitor ]}
  '';
}
