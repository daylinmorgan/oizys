{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
  environment.systemPackages = (with pkgs; [ neovim ]);
  users.users.nixos = {
     openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkezPIhB+QW37G15ZV3bewydpyEcNlYxfHLlzuk3PH9"
      ];
    };
}
