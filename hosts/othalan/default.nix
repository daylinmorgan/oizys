{
  lib,
  enabled,
  enableAttrs,
  listify,
  config,
  ...
}:

let
  inherit (lib.strings) hasPrefix splitString;
  inherit (builtins) readFile filter;
  readLanguageSettings = f: f |> readFile |> splitString "\n" |> filter (line: !(hasPrefix "#" line));
in
{

  oizys =
    {
      nix-ld = enabled // {
        overkill = enabled;
      };
      languages = readLanguageSettings ./settings/languages;
      # languages = "misc|nim|node|nushell|python|tex|typst" |> listify;
    }
    // (
      ''
        desktop
        hp-scanner
        hyprland
        chrome
        vpn
        backups
        llm
        vbox
        podman
        docker
        utils
      ''
      |> listify
      |> enableAttrs
    );

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
  };
}
