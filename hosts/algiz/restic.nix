{
  config,
  ...
}:
{

  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    # in practice I don't know that it would ever be possible to restore these directories
    # but it's better than nothing
    user = "root";

    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = config.sops.secrets.restic-algiz.path;
    paths =
      [
        "git"
        "gotosocial"
        "caddy"
        "wedding-website"
        "bsky-pds"
        "wiki"
      ]
      |> map (s: "/home/daylin/services/${s}/");
  };
}
