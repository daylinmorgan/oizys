{
  pkgs,
  config,
  mkOizysModule,
  ...
}:
mkOizysModule config "chrome" {
  programs.chromium = {
    enable = true;

    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "gfbliohnnapiefjpjlpjnehglfpaknnc" # surfingkeys
      "pbmlfaiicoikhdbjagjbglnbfcbcojpj" # simplify gmail
      "oemmndcbldboiebfnladdacbdfmadadm" # pdf viewer
      "clngdbkpkpeebahjckkjfobafhncgmne" # stylus
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "ekhagklcjbdpajgpjgmbionohlpdbjgc" # zotero connector

      "bkkmolkhemgaeaeggcmfbghljjjoofoh" # catppuccin chrome theme
      "lnjaiaapbakfhlbjenjkhffcdpoompki" # catppuccin github file icons
    ];
  };

  environment.systemPackages = with pkgs; [
    # (chromium.override {
    #   commandLineArgs = [ "--force-dark-mode" ];
    #   enableWideVine = true;
    # })

    (google-chrome.override {
      commandLineArgs = [ "--force-dark-mode" ];
    })
  ];
}
