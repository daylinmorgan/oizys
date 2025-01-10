{
  lib,
  fetchFromGitHub,
  buildNimPackage,
  # deps
  openssl,
  nim,
  makeWrapper,

}:
buildNimPackage (finalAttrs: {
  pname = "nimble";
  version = "0.16.4-unstable";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "f1ee5ff7b5f8211f9a236ffd2562a30b7ea57104";
    # rev = "v${finalAttrs.version}";
    hash = "sha256-yf/aTHvwWIEKvyIJ80pgryih0FKoZdzRoje2IPwMJZw=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl ];

  nimFlags = [ "--define:git_revision_override=${finalAttrs.src.rev}" ];

  doCheck = false; # it works on their machine

  postInstall = ''
    wrapProgram $out/bin/nimble \
      --suffix PATH : ${lib.makeBinPath [ nim ]}
  '';

  meta = {
    description = "Package manager for the Nim programming language";
    homepage = "https://github.com/nim-lang/nimble";
    license = lib.licenses.bsd3;
    mainProgram = "nimble";
  };
})
