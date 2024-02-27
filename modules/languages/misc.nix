{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.oizys.languages;
in {
  config = mkIf (builtins.elem "misc" cfg) {
    environment.systemPackages = with pkgs; [
      go
      rustup
    ];
  };
}
