{
  lib,
  fetchFromGitHub,
  buildNimPackage,

  # deps
  openssl,
  nim,
  makeWrapper,

  # options
  nix-update-script,
  useSystemNim ? true,
}:
buildNimPackage (finalAttrs: {

  pname = "nimble";
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    # rev = "v${finalAttrs.version}";
    rev = "a399f502dec7ffcd905c1cf54b13274ad990bada"; # not tagged
    hash = "sha256-39d9EsS0opz6vQzSE91gBRQbaTPeebVQLf/QdJoaD8o=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl ];

  nimFlags = [ "--define:git_revision_override=${finalAttrs.src.rev}" ];

  doCheck = false; # it works on their machine

  postInstall =
    let
      wrapperFlags = lib.concatStringsSep " " (
        [ "--suffix PATH : ${lib.makeBinPath [ nim ]}" ]
        ++ lib.optionals useSystemNim [
          "--add-flag \"--nim:${nim}/bin/nim\""
          "--add-flag '--useSystemNim'"
        ]
      );
    in
    "wrapProgram $out/bin/nimble ${wrapperFlags}";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Package manager for the Nim programming language";
    homepage = "https://github.com/nim-lang/nimble";
    license = lib.licenses.bsd3;
    mainProgram = "nimble";
  };
})
