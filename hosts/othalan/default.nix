{
  enabled,
  enableAttrs,
  listify,
  config,
  ...
}:
{
  oizys =
    {
      nix-ld = enabled // {
        overkill = enabled;
      };
      languages =
        "misc|nim|node|nushell|python|tex"
        # + "roc|zig"
        |> listify;
    }
    // (
      # llm
      ''
        vpn|desktop|hyprland|chrome
        backups|hp-scanner|llm
        podman|docker|vbox
      ''
      |> listify
      |> enableAttrs
    );

  sops.defaultSopsFile = ./secrets.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.restic-othalan = {
    # Permission modes are in octal representation (same as chmod),
    mode = "0440";
    # It is recommended to get the group/name name from
    # `config.users.users.<?name>.{name,group}` to avoid misconfiguration
    owner = config.users.users.daylin.name;
    group = config.users.users.daylin.group;
  };
}
