{
  lixVersion = "git";
  substituters = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-cache.dayl.in/oizys"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "oizys:2Sdu3lyOnNLeEYF2A3Hu3S5uqFQRe66DNwuFDneQs4M="
    ];
  };
  nixpkgs-overlays = { };
  self-overlays = [ ];
}
