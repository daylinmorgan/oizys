{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  # cfg = config.oizys.languages;
  langEnabled = name: builtins.elem name config.oizys.languages;
in {
  config = mkIf (langEnabled "tex") {
    environment.systemPackages = with pkgs; [
      texlive.combined.scheme-full
    ];
  };
}
