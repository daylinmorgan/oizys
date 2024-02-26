{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.vivaldi;
in {
  options.vivaldi.enable = mkEnableOption "enable vivaldi + extensions";
  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;

      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "gfbliohnnapiefjpjlpjnehglfpaknnc" # surfingkeys
        "pbmlfaiicoikhdbjagjbglnbfcbcojpj" # simplify gmail
        "oemmndcbldboiebfnladdacbdfmadadm" # pdf viewer
        "clngdbkpkpeebahjckkjfobafhncgmne" # stylus
      ];
    };

    environment.systemPackages = with pkgs; [
      (vivaldi.override {
        commandLineArgs = [
          "--force-dark-mode"
        ];
        proprietaryCodecs = true;
      })
    ];
  };
}
