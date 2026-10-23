inputs: final: prev: {
  # https://github.com/NixOS/nixpkgs/issues/576985
  udiskie = prev.udiskie.overridePythonAttrs (_old: {
    doCheck = false;
  });
}
