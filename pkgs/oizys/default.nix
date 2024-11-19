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
  nimbleDepsHash = "sha256-IWdlWC+j2h15WjVXXdDyxDZsb0/Ti1+jy6RfmqHFkjs=";

  meta = {
    description = "nix begat oizys";
  };
}
