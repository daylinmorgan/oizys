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
  version = "0.22.2-unstable";

  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    # rev = "v${finalAttrs.version}";
    rev = "a21c96f7c4612332d8688bf95a8a23b011d52bef";
    hash = "sha256-6edakeWjYzgebQLnSyZ6e04dFxg5eJ9XfhXHb/NQQ3w=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl ];

  nimFlags = [ "--define:git_revision_override=${finalAttrs.src.rev}" ];

  doCheck = false; # it works on their machine

  postInstall = ''
    wrapProgram $out/bin/nimble \
      --suffix PATH : ${lib.makeBinPath [ nim ]} \
      --add-flag "--nim:${nim}/bin/nim" \
      --add-flag '--useSystemNim'
  '';

  meta = {
    description = "Package manager for the Nim programming language";
    homepage = "https://github.com/nim-lang/nimble";
    license = lib.licenses.bsd3;
    mainProgram = "nimble";
  };
})
