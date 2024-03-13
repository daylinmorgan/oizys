{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIfIn;
  cfg = config.oizys.languages;
in {
  config = mkIfIn "tex" cfg {
    environment.systemPackages = with pkgs; [
      texlive.combined.scheme-full
    ];
  };
}
