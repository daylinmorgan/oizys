{ fetchFromGitHub, buildNimPackage }:
buildNimPackage (finalAttrs: {
  pname = "nph";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "arnetheduck";
    repo = "nph";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9t5VeGsxyytGdu7+Uv/J+x6bmeB5+eQapbyp30iPxqs=";
  };

  doCheck = false;
}
)
