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
  <td>Vultr VPS hosting forgejo,soft-serve & gts</td>
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
oizys <cmd> [opts]
  commands:
    dry     poor man's nix flake check
    boot    nixos-rebuild boot
    switch  nixos-rebuild switch
    cache   build and push to cachix
    build   build system flake

  options:
    -h|--help    show this help
       --host    hostname (current host)
    -f|--flake   path to flake ($FLAKE_PATH or $HOME/styx)
    -c|--cache   name of cachix binary cache (daylin)
       --no-nom  don't use nix-output-monitor
```


## oizys?

Oizys was birthed by the goddess Nyx/Nix and embodies suffering and misery. Which is all that awaits you if you embrace nix.

---

> [!NOTE]
> I don't use home-manager to manager my shell/user configs. You can find those in my separate `chezmoi`-managed [`dotfiles`](https://git.dayl.in/daylin/dotfiles) repository.

