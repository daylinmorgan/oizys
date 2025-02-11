## nix begat oizys
import std/[os, osproc, sequtils, strformat, strutils, tables]
import hwylterm, hwylterm/[hwylcli]
import oizys/[context, github, nix, logging, utils, exec]

proc checkExes() =
  if findExe("nix") == "":
    fatalQuit "oizys requires nix"

checkexes()

hwylCli:
  name "oizys"
  settings ShowHelp
  flags:
    [global]
    flake:
      T string
      ? "path/to/flake"
    host:
      T seq[string]
      ? "host(s) to build"
    verbose:
      T Count
      ? "increase verbosity (up to 2)"
      - v
      * Count(val: 0)
    `reset-cache`:
      ? "set cache timeout to 0"
      ident resetCache

    [misc]
    yes:
      - y
      ? "skip all confirmation prompts"
    minimal:
      ? "set minimal"
      - m
  preSub:
    setupLoggers()
    updateContext(host, flake, verbose, resetCache)

  subcommands:
    [build]
    ... "nix build"
    positionals:
      args seq[string]
    flags:
      ^minimal
      nom:
        ? "use nom"
    run:
      nixBuild(minimal, nom, args)

    [cache]
    ... "build and push store paths"
    positionals:
      args seq[string]
    flags:
      name:
        T string
        ? "name of binary cache"
        * "oizys"
      service:
        T string
        ? "name of cache service"
        * "attic"
      jobs:
        T int
        ? "jobs when pushing paths"
        * countProcessors()
        - j
      `dry-run`:
        - n
        ? "don't actually build derivations"
    run:
      nixBuildWithCache(name, args, service, jobs, `dry-run`)

    [ci]
    ... "builtin ci"
    subcommands:
      [update]
      ... "build current and updated hosts"
      positionals:
        args seq[string]
      run:
        ciUpdate(args)

    [gha]
    ... """
    trigger GHA

    examples:
      [b]oizys gha update[/] --inputs:hosts:othalan,algiz,mannaz
    """
    positionals:
      workflow string
    flags:
      inputs:
        T seq[KVString]
        ? "inputs for dispatch"
      `ref`:
        T string
        ? "git ref/branch/tag to trigger workflow on"
        * "main"
    run:
      # TODO: support file operations like gh
      # i.e. @flake.lock means read a file at flake.lock and use it's contents as a string
      let inputs =
        inputs.mapIt((it.key, it.val)).toTable()
      createDispatch(workflow, `ref`, inputs)

    [dry]
    ... "dry run build"
    positionals:
      args seq[string]
    flags:
      ^minimal
    run:
      nixBuildHostDry(minimal, args)

    [os]
    ... "nixos-rebuild [italic]subcmd[/]"
    positionals:
      subcmd NixosRebuildSubcmd
      args seq[string]
    flags:
      remote:
        ? "host is remote"
        - r
    run:
      nixosRebuild(subcmd, args, remote)

    [output]
    ... "nixos config attr"
    flags:
      ^minimal
    run:
      if not minimal:
        echo nixosConfigAttrs().join(" ")
      else:
        showOizysDerivations()

    [update]
    ... "update and run nixos-rebuild"
    flags:
      ^yes
      preview:
        - p
        T bool
        ? "show preview and exit"
    run:
      let hosts = getHosts()
      if hosts.len > 1: fatalQuit "operation only supports one host"
      let run = getLastUpdateRun()
      echo fmt"run created at: {run.created_at}"
      echo "nvd diff:\n", getUpdateSummary(run.id, hosts[0])
      if preview: quit 0
      if yes or confirm("Proceed with system update?"):
        updateRepo()
        nixosRebuild(NixosRebuildSubcmd.switch)

    [hash]
    ... "collect build hash from failure"
    positionals:
      installable string
    run:
      stdout.write getBuildHash(installable)

    [narinfo]
    ... """
    check active caches for nix derivation

    by default will use [yellow]nix config show[/] to determine
    the binary cache urls
    """
    positionals:
      installables seq[string]
    flags:
      cache:
        ? "url of nix binary cache, can be repeated"
        T seq[string]
    run:
      if installables.len == 0:
        fatalQuit "expected at least one positional argument"
      checkForCache(installables, cache)

    [lock]
    ... """
    check lock status for duplicates

    currently just runs `jq < flake.lock '.nodes | keys[] | select(contains("_"))' -r`
    """
    run:
      # use absolute value for flake.lock?
      if not isLocal():
        quit "`oizys lock` should be run with a local flake"

      discard runCmd("nix flake lock " & getFlake())
      let lockfile = getFlake() / "flake.lock"
      quitWithCmd(fmt"""jq '.nodes | keys[] | select(contains("_"))' -r {lockFile}""")

