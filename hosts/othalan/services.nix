{
  config,
  ...
}:
{
  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = config.sops.secrets.restic-othalan.path;
    paths =
      [
        "stuff"
        "dev"
      ]
      |> map (p: "/home/daylin/${p}");
  };
}
