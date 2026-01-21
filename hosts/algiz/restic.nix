{
  lib,
  config,
  ...
}:
let
  prefixPaths = prefix: paths: paths |> lib.listify |> map (p: "${prefix}/${p}");
  # these have mixed reliance on active state and backing them up like this is problematic
  # in practice, I don't know that it would ever be possible to restore these directories if the backups aren't intentional
  # I should design a sepearate script/service which turns off all of these and then backs them up
  varLibPaths = ''
    continuwuity
    forgejo
    linkding
    otterwiki
    soft-serve
    gotosocial
    pds
  '';
  paths = (varLibPaths |> prefixPaths "/var/lib");
in
{
  sops.secrets.restic-algiz = { };
  services.restic.backups.gdrive = {
    user = "root";
    rcloneConfigFile = "/home/daylin/.config/rclone/rclone.conf";
    repository = "rclone:g:archives/algiz";
    passwordFile = config.sops.secrets.restic-algiz.path;
    inherit paths;
  };
}
