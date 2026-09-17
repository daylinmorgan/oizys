inputs: final: prev: {
  # see https://github.com/Mic92/sops-nix/issues/983
  buildGo125Module = prev.buildGoModule;
}
