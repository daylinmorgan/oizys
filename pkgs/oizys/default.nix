{
  lib,
  openssl,
  buildNimblePackage,
}:
buildNimblePackage {
  name = "oizys";
  verions = "unstable";
  src = lib.cleanSource ./.;
  nativeBuildInputs = [ openssl ];
  nimbleDepsHash = "sha256-dFJw/m7D5UFUrHH7exsyHknt8WHIK1QIQATNd5l7FZA=";

  meta = {
    description = "nix begat oizys";
  };
}
