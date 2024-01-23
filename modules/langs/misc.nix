{config, lib,pkgs,...}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages.misc;
in
{
  options.languages.misc.enable = mkEnableOption "go + rustup";
  config = mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    go
    rustup
  ];
};
}
