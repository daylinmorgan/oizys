{
  enabled,
  pkgs,
  ...
}:
{
  imports = [
    ./services
  ];

  oizys = {
    rune.motd = enabled;
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "gitea" ''
      ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
    '')
  ];

  # git user handles the forgjo ssh authentication
  users.users.git.isNormalUser = true;
 }
