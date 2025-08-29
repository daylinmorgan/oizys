{
  inputs,
  pkgs,
  enabled,
  ...
}:
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html#_nix-shell_vs_nix_shell
  # use the same nixpkgs for nix-shell -p hello style commands
  # I don't know that this is necesary...
  # nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" ];
  # environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

  environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
  ];

  programs.nix-index-database.comma = enabled;

  # nix-index didn't like this being enabled?
  programs.command-not-found.enable = false;

  # I'm getting errors related to a non-existent nix-index?
  programs.nix-index.enableZshIntegration = false;
  programs.nix-index.enableBashIntegration = false;
  programs.nix-index.enableFishIntegration = false;

  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig"
    fi
  '';

  programs.nh = enabled // {
    clean = enabled;
  };
}
