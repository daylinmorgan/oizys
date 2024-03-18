{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.oizys.chrome;
in {
  options.oizys.chrome.enable = mkEnableOption "enable chrome + extensions";
  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;

      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "gfbliohnnapiefjpjlpjnehglfpaknnc" # surfingkeys
        "pbmlfaiicoikhdbjagjbglnbfcbcojpj" # simplify gmail
        "oemmndcbldboiebfnladdacbdfmadadm" # pdf viewer
        "clngdbkpkpeebahjckkjfobafhncgmne" # stylus
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };

    environment.systemPackages = with pkgs; [
      (google-chrome.override {
        commandLineArgs = [
          "--force-dark-mode"
        ];
      })
    ];
  };
}
