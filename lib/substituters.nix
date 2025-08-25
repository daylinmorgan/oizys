{
  substituters = [
    "https://cache.nixos.org/"
    "https://nix-cache.dayl.in/oizys"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "oizys:8R6ZZzI9+2ug4S6dyknAelQgOy3D5k/rCzAUu8/90BY="
    # i regenerated the cache but I think packages still exist signed by this key.
    "oizys:DSw3mwVMM/Y+PXSVpkDlU5dLwlORuiJRGPkwr5INSMc="
  ];
}
