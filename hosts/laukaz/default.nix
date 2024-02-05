{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  # system = {
  #   # Disable zstd compression
  #   build.sdImage.compressImage = false;
  # };
  enviroment.systemPackages = with pkgs; [
    git
  ];
  security.sudo.wheelNeedsPassword = false;
}
