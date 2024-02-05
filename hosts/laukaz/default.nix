{
  inputs,
  pkgs,
  ...
}: {
  languages = {
    python = true;
  };
  cli.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
