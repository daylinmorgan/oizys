export NPM_PREFIX="$(npm prefix -g)"
path=(
  "$NPM_PREFIX/bin"
  $path
)
