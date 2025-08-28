{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in
{
  config = mkIfIn "rust" cfg {
    environment.systemPackages = with pkgs; [
      # should I just use cargo and rustc instead?
      rustup
      rust-analyzer
    ];
  };
}
