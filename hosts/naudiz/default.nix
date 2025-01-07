{ inputs, enabled, ... }:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];
  wsl = enabled // {
    defaultUser = "daylin";
  };

  # don't delete this you foo bar
  system.stateVersion = "23.11"; # Did you read the comment?
}
