## nix begat oizys
import std/[os, osproc, sequtils, strformat, strutils]
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
    debug:
      ? "enable debug mode"
      - d
    resetCache:
      ? "set cache timeout to 0"
      - r
    [misc]
    yes:
      - y
      ? "skip all confirmation prompts"
    minimal:
      ? "set minimal"
      - m
  preSub:
    setupLoggers(debug)
    updateContext(host, flake, debug, resetCache)

  subcommands:
    [build]
    ... "nix build"
    flags:
      ^minimal
    run:
      nixBuild(minimal, args)

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
      setupLoggers(debug)
      updateContext(host, flake, debug, resetCache)
    subcommands:
      [update]
      ... "build current and updated hosts"
      run:
        ciUpdate(args)

    [gha]
    ... "trigger GHA"
    flags:
      # make a key/value input that is passed to workflows and encoded in json
      # i.e. --input:ref:main
      `ref`:
        T string
        ? "git ref/branch/tag to trigger workflow on"
        * "main"
    run:
      if args.len == 0: fatalQuit "expected workflow file name"
      createDispatch(args[0], `ref`)

    [dry]
    ... "dry run build"
    flags:
      ^minimal
    run:
      nixBuildHostDry(minimal, args)

    [os]
    ? "[b]oizys os[/] [i]subcmd[/] [[[faint]flags[/]]"
    ... "nixos-rebuild [italic]subcmd[/]"
    run:
      if args.len == 0: fatalQuit "please provide subcmd"
      let subcmd = args[0]
      if subcmd notin nixosSubcmds:
        fatalQuit(
          &"unknown nixos-rebuild subcmd: {subcmd}\nexpected one of: \n" &
          nixosSubcmds.mapIt("  " & it).join("\n")
        )
      nixosRebuild(subcmd, args[1..^1])

    [output]
    ... "nixos config attr"
    run:
      echo nixosConfigAttrs().join(" ")

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
        nixosRebuild("switch")

