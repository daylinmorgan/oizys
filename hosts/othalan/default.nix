{
  config,
  enabled,
  lib,
  ...
}:
{
  oizys = {
    nix-ld = enabled // {
      overkill = enabled;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.mullvad-userpass = { };
    secrets."mullvad_ca.crt" = { };

    secrets.restic-othalan = {
      # Permission modes are in octal representation (same as chmod),
      mode = "0440";
      # It is recommended to get the group/name name from
      # `config.users.users.<?name>.{name,group}` to avoid misconfiguration
      owner = config.users.users.daylin.name;
      group = config.users.users.daylin.group;
    };
    secrets.wg-conf = {
      sopsFile = ../../secrets/secrets.yaml;
    };
  };

  networking.wg-quick.interfaces = {
    # AirVPN - North America
    air-na = {
      configFile = config.sops.secrets.wg-conf.path;
      autostart = false;
    };

  };

  services.restic.backups.gdrive = {
    user = "daylin";
    repository = "rclone:g:archives/othalan";
    passwordFile = config.sops.secrets.restic-othalan.path;
    paths =
      ''
        stuff
        dev
      ''
      |> lib.listify
      |> map (p: "/home/daylin/${p}");
  };
}
