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
    ];
  };

  environment.systemPackages = with pkgs; [
    (google-chrome.override {
      commandLineArgs = [
        "--force-dark-mode"
      ];
    })
  ];
}
