{
  fetchFromGitHub,
  buildNimPackage,
  nim-nnl-update-script,
}:
buildNimPackage (finalAttrs: {
  pname = "nimlangserver";
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "langserver";
    rev = "v${finalAttrs.version}";
    hash = "sha256-IJbuM/AhPgyfe/1ONY8Nb46+gqjduVQOvkgGafgkhY4=";
  };

  doCheck = false;
  # nix run "github:daylinmorgan/nnl" -- result -o:pkgs/nim/nimlangserver/lock.json --git,=,bearssl,zlib
  lockFile = ./lock.json;

  # they have a tag (v.1.10.0) that breaks this
  # passthru.updateScript = nim-nnl-update-script {
  #   inherit (finalAttrs) pname version src;
  #   extraFlags = "--git,=bearssl,zlib";
  # };
})
