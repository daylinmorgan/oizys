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
  <td>
     <img src="https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png" height="100">
  </td>
  <td>othalan</td>
  <td>Thinkpad Carbon X1 Gen 9</td>
</tr>
<tr>
  <td>
    <img src="https://upload.wikimedia.org/wikipedia/commons/1/14/Runic_letter_algiz.png" height="100">
  </td>
  <td>algiz</td>
  <td>Hetzner VPS hosting forgejo, soft-serve & gts</td>
</tr>
<tr>
  <td>
    <img src="https://upload.wikimedia.org/wikipedia/commons/0/0c/Runic_letter_mannaz.png" height="100">
  </td>
  <td>mannaz</td>
  <td>Custom AMD Tower with Nvidia 1050ti</td>
</tr>
<tr>
  <td>
    <img src="https://upload.wikimedia.org/wikipedia/commons/b/b9/Runic_letter_naudiz.png" height="100">
  </td>
  <td>naudiz</td>
  <td>Nixos-WSL for those times I'm trapped on windows</td>
</tr>
</table>

## oizys cli

A small helper utility that mostly just wraps `nix` commands for convenience.

```sh
nix run "github:daylinmorgan/oizys"
```

```
usage:
  oizys subcmd [flags]

subcommands:
  build    nix build
  cache    build and push store paths
  ci       builtin ci
  gha      trigger GHA
  dry      dry run build
  os       nixos-rebuild subcmd
  output   nixos config attr
  update   update and run nixos-rebuild

flags:
     --flake      path/to/flake
     --host       host(s) to build
  -d --debug      enable debug mode
  -r --resetCache set cache timeout to 0
  -h --help       show this help
```

## oizys?

Oizys was birthed by the goddess Nyx/Nix and embodies suffering and misery. Which is all that awaits you if you embrace nix.

---

> [!NOTE]
> I don't use home-manager to manager my shell/user configs. You can find those in my separate `chezmoi`-managed [`dotfiles`](https://git.dayl.in/daylin/dotfiles) repository.
