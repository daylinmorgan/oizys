{
  pkgs,
  nixpkgs,
  ...
}: {
  nixpkgs.overlays = [
    # (import ../../overlays/nim {})
    (import ../../overlays/nimlsp {})
    (import ../../overlays/nimble {})
    (import ../../overlays/nim-atlas {})
  ];

  environment.systemPackages = with pkgs; [
    nim-atlas
    nim
    nimble
    nimlsp
  ];
}
