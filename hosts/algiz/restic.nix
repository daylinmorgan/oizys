{
  lib,
  config,
  ...
}:
let
  prefixPaths = prefix: paths: paths |> lib.listify |> map (p: "${prefix}/${p}");
  homePaths = ''
    git
    gotosocial
    wedding-website
    bsky-pds
    wiki
  '';
  optPaths = ''
    linkding
    otterwiki
    continuwuity
  '';
  paths = (homePaths |> prefixPaths "/home/daylin/services") ++ (optPaths |> prefixPaths "/opt");
in
{

  services.restic.backups.gdrive = {
    # in practice I don't know that it would ever be possible to restore these directories
    # but it's better than nothing
    user = "root";

    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = config.sops.secrets.restic-algiz.path;
    inherit paths;
  };
}
