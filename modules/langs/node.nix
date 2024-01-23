{config, lib,pkgs,...}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.languages.node;
in
{
  options.languages.node.enable = mkEnableOption "node";
  config = mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
        nodejs
    nodePackages.pnpm
  ];
};
}
