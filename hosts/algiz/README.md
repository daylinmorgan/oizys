<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/d/df/Runic_letter_algiz.svg">
<h1>Algiz</h1>
</div>

## Setting up git user for use with gitea originally

```sh
sudo -u git ssh-keygen -t rsa -b 4096 -C "Gitea Host Key"
sudo -u git cat /home/git/.ssh/id_rsa.pub | sudo -u git tee -a /home/git/.ssh/authorized_keys
sudo -u git chmod 600 /home/git/.ssh/authorized_keys
```


`/home/git/.ssh/authorized_keys` should Look like this:

```txt
# SSH pubkey from git user
ssh-rsa <Gitea Host Key>

# other keys from users
command="/usr/local/bin/gitea --config=/data/gitea/conf/app.ini serv key-1",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty <user pubkey>
```


Nixify this step....
cat <<"EOF" | sudo tee /usr/local/bin/gitea
#!/bin/sh
ssh -p 2222 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
EOF
sudo chmod +x /usr/local/bin/gitea
