{
  lib,
  config,
  ...
}:
let
  prefixPaths = paths: prefix: paths |> lib.listify |> map (p: "${prefix}/${p}");
  homePaths = ''
    git
    gotosocial
    wedding-website
    bsky-pds
    wiki
    continuwuity
  '';
  optPaths = "linkding/data";
in
{

  services.restic.backups.gdrive = {
    # directories created by gitea and soft-serve aren't world readable
    # in practice I don't know that it would ever be possible to restore these directories
    # but it's better than nothing
    user = "root";

    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = config.sops.secrets.restic-algiz.path;
    paths = (homePaths |> prefixPaths "/home/daylin/services") ++ (optPaths |> prefixPaths "/opt");
  };
}
