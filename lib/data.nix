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
  ## nixpkgs-unstable = { pkg = PR-num };
  nixpkgs-overlays = { };
  self-overlays = [
    "nim-atlas"
    "firefox"
    "nimble"
  ];
}
