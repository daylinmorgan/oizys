<div align="center">
<h1>oizys</h1>
<p>nix begat oizys</p>
</div>

This is a custom multi-host [nixos](https://nixos.org) flake.
See below for the currently maintained hosts.

## hosts

<table>
  <tr>
    <th>rune</th>
    <th>name</th>
    <th>system</th>
  </tr>
<tr>
  <td><img src="https://upload.wikimedia.org/wikipedia/commons/7/70/Runic_letter_othalan.svg"></td>
  <td>othalan</td>
  <td>Thinkpad Carbon X1 Gen 9</td>
</tr>
<tr>
  <td><img src="https://upload.wikimedia.org/wikipedia/commons/d/df/Runic_letter_algiz.svg"></td>
  <td>algiz</td>
  <td>Hetzner Cloud hosting forgejo,soft-serve & gts</td>
</tr>
<tr>
  <td><img src="https://upload.wikimedia.org/wikipedia/commons/5/57/Runic_letter_mannaz.svg"></td>
  <td>mannaz</td>
  <td>Custom AMD Tower with Nvidia 1050ti</td>
</tr>
</table>



## oizys cli

A small helper utility that mostly just wraps `nix` commands for convenience.

```sh
nix run "github:daylinmorgan/oizys"
```

```
nix begat oizys

Usage:
  oizys [command]

Available Commands:
  boot                    nixos rebuild boot
  build                   A brief description of your command
  cache                   build and push to cachix
  dry                     poor man's nix flake check
  help                    Help about any command
  output                  show nixosConfiguration attr
  switch                  nixos rebuild switch

Flags:
      --flake string   path to flake ($OIZYS_DIR or $HOME/oizys)
  -h, --help           help for oizys
      --host string    host to build (current host)

Use "oizys [command] --help" for more information about a command.
```

## oizys?

Oizys was birthed by the goddess Nyx/Nix and embodies suffering and misery. Which is all that awaits you if you embrace nix.

---

> [!NOTE]
> I don't use home-manager to manager my shell/user configs. You can find those in my separate `chezmoi`-managed [`dotfiles`](https://git.dayl.in/daylin/dotfiles) repository.

