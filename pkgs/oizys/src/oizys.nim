## nix begat oizys
import std/[os, osproc, sequtils, strformat, strutils]
import hwylterm, hwylterm/[hwylcli, logging]
import oizys/[context, github, nix, logging]

proc checkExes() =
  if findExe("nix") == "":
    fatalQuit "oizys requires nix"

checkexes()
hwylCli:
  name "oizys"
  globalFlags:
    flake "path/to/flake"
    host:
      T seq[string]
      ? "host(s) to build"
      # - h conflicts with autoadded help short flag
    debug:
      T bool
      ? "enable debug mode"
      - d
    resetCache:
      T bool
      ? "set cache timeout to 0"
      - r
  preSub:
    setupLoggers(debug)
    updateContext(host, flake, debug, resetCache)
  subcommands:

    --- build
    ... "nix build"
    flags:
      minimal:
        T bool
        - m
    run:
      nixBuild(minimal, args)

    --- cache
    ... "build and push store paths"
    flags:
      name:
        * "oizys"
        ? "name of binary cache"
      service:
        * "attic"
      jobs:
        * countProcessors()
        ? "jobs when pushing paths"
        T int
    run:
      nixBuildWithCache(name, args, service, jobs)

    --- ci
    ... "trigger GHA"
    flags:
      `ref`:
        ? "git ref/branch/tag to trigger workflow on"
        * "main"
    run:
      if args.len == 0: fatalQuit "expected workflow file name"
      createDispatch(args[0], `ref`)

    --- dry
    ... "dry run build"
    flags:
      minimal:
        T bool
    run:
      nixBuildHostDry(minimal, args)

    --- os
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

    --- output
    ... "nixos config attr"
    flags:
      yes:
        T bool
        ? "skip all confirmation prompts"
    run:
      echo nixosConfigAttrs().join(" ")

    --- update
    ... "update and run nixos-rebuild"
    flags:
      yes:
        T bool
        ? "skip all confirmation prompts"
      preview:
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
  
