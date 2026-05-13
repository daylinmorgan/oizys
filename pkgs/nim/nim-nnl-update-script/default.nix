{
  writeShellScript,
  lib,
}:
{
  pname,
  version,
  src,
  extraFlags ? "",
}:
let
  homepage = src.meta.homepage;
  tagPrefix = lib.removeSuffix version src.rev;
in
writeShellScript "update-${pname}" ''
  set -euo pipefail
  nix-update --flake "$UPDATE_NIX_ATTR_PATH"
  version=$(nix eval --raw --impure ".#$UPDATE_NIX_ATTR_PATH.version")
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT
  git clone --depth 1 --branch "${tagPrefix}$version" \
    ${homepage} "$tmpdir"
  nix run "github:daylinmorgan/nnl" -- "$tmpdir" ${extraFlags}
''
