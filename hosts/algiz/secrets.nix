{ ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;

    # by default is accessible only by root:root which should work with above service
    secrets.restic-algiz = { };
    secrets.atticd-env = { };
    secrets.harmonia-key = { };
  };

}
