{
  lixVersion = "git";
  lixModule = true;
  substituters = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-cache.dayl.in/oizys"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "oizys:OcgNR7G1/au+NnIh12LzW27EXOfHGZalJNgSJSYJFQQ="
    ];
  };
  # nixpkgs-unstable = { pkg = PR-num };
  nixpkgs-overlays = {
    # nixpkgs-unstable = {
    #   niri = 546004;
    #   nimble = 542689;
    # };
  };
  # unfree packages permitted in both the flake's pkgs and host builds
  unfree-packages = [
    "firefox-nightly"
    "hplip"
    # vscode's wrapper and unwrapped derivation are named separately
    "code"
    "vscode"
    "google-chrome"
    # mannaz
    "nvidia-x11"
    "nvidia-settings"
    "broadcom-sta"
  ];
  self-overlays = [
    "nim-atlas"
    "firefox"
    # "nimble"
  ];
}
