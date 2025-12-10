{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib)
    types
    mkOption
    mkIf
    mkMerge
    ;
  cfg = config.catppuccin;
in
{
  options.catppuccin.enable = mkOption {
    default = true;
    type = types.bool;
    description = "enable catppuccin theming";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      boot.kernelParams = [
        "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
        "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
        "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
      ];
    })
    (mkIf (config.oizys.desktop.enable && cfg.enable) {
      environment.systemPackages = with pkgs; [
        (catppuccin-gtk.override {
          accents = [ "pink" ];
          variant = "mocha";
        })

        (catppuccin-kvantum.override {
          variant = "mocha";
          accent = "pink";
        })
        catppuccin-cursors.mochaDark
      ];
    })
  ];
}
