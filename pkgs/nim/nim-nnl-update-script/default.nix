{
  writeShellApplication,
  nix-update,
  git,
  nix,
}:
{
  extraFlags ? "",
}:
let
  name = "update-nim-package";
  script = writeShellApplication {
    inherit name;
    runtimeInputs = [
      nix-update
      git
      nix
    ];
    text = ''
      set -euo pipefail
      nix-update --flake "$UPDATE_NIX_ATTR_PATH"
      version=$(nix eval --raw --impure ".#$UPDATE_NIX_ATTR_PATH.version")
      homepage=$(nix eval --raw --impure ".#$UPDATE_NIX_ATTR_PATH.src.meta.homepage")
      rev=$(nix eval --raw --impure ".#$UPDATE_NIX_ATTR_PATH.src.rev")
      tagPrefix="''${rev%"$version"}"

      tmpdir=$(mktemp -d)
      trap 'rm -rf "$tmpdir"' EXIT
      git clone --depth 1 --branch "''${tagPrefix}$version" \
        "$homepage" "$tmpdir"
      nix run "github:daylinmorgan/nnl" -- "$tmpdir" ${extraFlags}
    '';
  };
in
"${script}/bin/${name}"
