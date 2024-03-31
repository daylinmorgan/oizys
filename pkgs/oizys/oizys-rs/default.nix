{
  installShellFiles,
  rustPlatform,
  nix-output-monitor,
}:
rustPlatform.buildRustPackage {
  pname = "oizys";
  version = "unstable";
  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [installShellFiles];
  buildInputs = [nix-output-monitor];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys --completions zsh)
  '';
}
