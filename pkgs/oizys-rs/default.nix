{rustPlatform}:
rustPlatform.buildRustPackage {
  pname = "oizys";
  version = "unstable";
  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
}
