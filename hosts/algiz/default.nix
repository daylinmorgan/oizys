{
  enabled,
  enableAttrs,
  pipeList,
  ...
}:
{
  oizys = {
    rune.motd = enabled;
    languages = "nim|node|python|nushell" |> pipeList;
  } // ("docker|backups|nix-ld" |> pipeList |> enableAttrs);

  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = "/home/daylin/.config/restic/algiz-pass";
    paths = [
      "/home/daylin/services/git/"
      "/home/daylin/services/gotosocial/"
      "/home/daylin/services/caddy/"
      "/home/daylin/services/wedding-website/"
    ];
  };

  # git user handles the forgjo ssh authentication
  users.users.git.isNormalUser = true;
}
