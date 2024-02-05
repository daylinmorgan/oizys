{
  inputs,
  nixpkgs,
  pkgs,
  ...
}: {
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  system = {
    # Disable zstd compression
    build.sdImage.compressImage = false;
  };
  security.sudo.wheelNeedsPassword = false;
}
