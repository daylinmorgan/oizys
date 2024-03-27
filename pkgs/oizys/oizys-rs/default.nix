{
  installShellFiles,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "oizys";
  version = "unstable";
  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [installShellFiles];

  postInstall = ''
    installShellCompletion --cmd oizys \
      --zsh <($out/bin/oizys --completions zsh)
  '';
}
