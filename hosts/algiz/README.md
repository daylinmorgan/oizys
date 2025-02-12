<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/d/df/Runic_letter_algiz.svg">
<h1>algiz</h1>
</div>

## Setting up git user for use with gitea originally

```sh
sudo -u git ssh-keygen -t rsa -b 4096 -C "Gitea Host Key"
sudo -u git cat /home/git/.ssh/id_rsa.pub | sudo -u git tee -a /home/git/.ssh/authorized_keys
sudo -u git chmod 600 /home/git/.ssh/authorized_keys
```

`/home/git/.ssh/authorized_keys` should look like this:

```txt
# SSH pubkey from git user
ssh-rsa <Gitea Host Key>

# other keys from users
command="/usr/local/bin/gitea --config=/data/gitea/conf/app.ini serv key-1",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty <user pubkey>
```

To point gitea/forgejo to the shim gitea binary for SSH I symlink the current system version to `/usr/local/bin/gitea`.

```sh
ln -s /run/current-system/sw/bin/gitea /usr/local/bin/gitea
```

## Setting up Attic

Generated a key using command provided in attic docs:

```sh
nix run nixpkgs#openssl -- genrsa -traditional 4096 | base64 -w0
```

And wrote `ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="output from above"` to `/etc/attic.env`

I generated a token to configure the caches using the following command:

```
atticd-atticadm make-token --sub daylin --push "*" --pull "*" --validity '1y' --create-cache "*" --configure-cache "*" --configure-cache-retention "*" --destroy-cache "*" --delete "*"
```

If I handled secrets via `sops` or `agenix` I think this could be stored directly in the repo.
I also had to modify the firewall so that docker would forward along the requests by caddy to `host.docker.internal` correctly.

## Setting up Harmonia

Generated a signing key with the following command:

```sh
nix-store --generate-binary-cache-key nix-cache.dayl.in-1 ./secret ./public
```

public key:

```txt
nix-cache.dayl.in-1:lj22Sov7m1snupBz/43O1fxyEfy/S7cxBpweD7iREcs=
```

Then enabled the service using the nixos module and used sops to store the private key.
