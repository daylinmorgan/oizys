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
  version = "0.18.0";
  src = fetchFromGitHub {
    owner = "nim-lang";
    repo = "nimble";
    rev = "v${finalAttrs.version}";
    hash = "sha256-HFuJiozRsRlVIXIv+vRjsfosrBlWfnUYtep27Fy/PPA=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ openssl ];

  nimFlags = [ "--define:git_revision_override=${finalAttrs.src.rev}" ];

  doCheck = false; # it works on their machine

  # TODO: remove
  preConfigure = ''
    echo -e "\n" >> config.nims
  '';

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
