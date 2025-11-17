{ ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;

    secrets.restic-algiz = { };
    secrets.atticd-env = { };
    secrets.harmonia-key = { };
    secrets.continuwuity-env = { };
  };
}
