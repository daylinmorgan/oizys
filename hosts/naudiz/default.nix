{ inputs, enabled, ... }:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];
  oizys = {
    nix-ld = enabled;
    languages = [

      "python"
      "node"
    ];
  };
  wsl = enabled // {
    defaultUser = "daylin";
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
