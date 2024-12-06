{ pkgs, flake, ... }:
{
  environment.systemPackages =
    [
      # not technically git ¯\_(ツ)_/¯
      (flake.pkg "jj")

    ]
    ++ (with pkgs; [
      git
      git-lfs

      gh
      lazygit
      delta
    ]);
}
