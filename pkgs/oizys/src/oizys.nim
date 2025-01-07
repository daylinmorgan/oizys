## nix begat oizys
import std/[os, osproc, sequtils, strformat, strutils, tables]
import hwylterm, hwylterm/[hwylcli]
import oizys/[context, github, nix, logging]

proc checkExes() =
  if findExe("nix") == "":
    fatalQuit "oizys requires nix"

checkexes()

hwylCli:
  name "oizys"
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
    resetCache:
      ? "set cache timeout to 0"
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
    flags:
      ^minimal
      nom:
        ? "use nom"
    run:
      nixBuild(minimal, nom, args)

    [cache]
    ... "build and push store paths"
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
    run:
      nixBuildWithCache(name, args, service, jobs)

    [ci]
    ... "builtin ci"
    # current behavior adds this block twice...
    # when really I want it to only happen in the lowest "subcommand"
    # needs to be fixed in hwylterm
    preSub:
      updateContext(host, flake, verbose, resetCache)
    subcommands:
      [update]
      ... "build current and updated hosts"
      run:
        ciUpdate(args)

    [gha]
    ... """
    trigger GHA

    examples:
      [b]oizys gha update[/] --inputs:hosts:othalan,algiz,mannaz
    """
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
      # i.e. @flake.lock means read a file a flake.lock and use it's contents
      if args.len == 0: fatalQuit "expected workflow file name"
      let inputs =
        inputs.mapIt((it.key, it.val)).toTable()
      createDispatch(args[0], `ref`, inputs)

    [dry]
    ... "dry run build"
    flags:
      ^minimal
    run:
      nixBuildHostDry(minimal, args)

    [os]
    ? "[b]oizys os[/] [i]subcmd[/] [[[faint]flags[/]]"
    ... "nixos-rebuild [italic]subcmd[/]"
    flags:
      remote:
        ? "host is remote"
        - r
    run:
      nixosRebuild(args, remote)

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
        nixosRebuild(["switch"])

