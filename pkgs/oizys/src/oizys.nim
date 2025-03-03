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
    flake(string, "path/to/flake")
    host(seq[string], "host(s) to build")
    v|verbose(Count(val:0), Count, "increase verbosity (up to 2)")
    `reset-cache`("set cache timeout to 0")
    b|bootstrap("enable bootstrap mode")

    [misc]
    y|yes "skip all confirmation prompts"
    m|minimal "set minimal"
  preSub:
    setupLoggers()
    updateContext(host, flake, verbose, `reset-cache`, bootstrap)

  subcommands:
    [build]
    ... "nix build"
    positionals:
      args seq[string]
    flags:
      ^minimal
      nom "use nom"
    run:
      nixBuild(minimal, nom, args)

    [cache]
    ... "build and push store paths"
    positionals:
      args seq[string]
    flags:
      name("oizys", string, "name/host of binary cache")
      service("attic", string, "name of cache service")
      j|jobs(countProcessors(),int, "jobs when pushing paths")
      n|`dry-run` "don't actually build derivations"
    run:
      if findExe("nix-eval-jobs") == "":
        fatalQuit bb"[b]oizys cache[/] requires [b]nix-eval-jobs[/]"
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
      inputs(seq[KVString], "inputs for dispatch")
      `ref`("main", string, "git ref/branch/tag to trigger workflow on")
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
      r|remote "host is remote"
    run:
      nixosRebuild(subcmd, args, remote)

    [output]
    ... "nixos config attr"
    flags:
      ^minimal
      s|system "show system path"
    run:
      if minimal and system:
        echo "--minimal and --system are mutually exclusive"
      elif minimal:
        echo missingDrvNixEvalJobs().fmtDrvsForNix()
      else:
        echo nixosAttrs(
          if system: "path"
          else: "build.toplevel"
        ).join(" ")

    [update]
    ... "update and run nixos-rebuild"
    flags:
      ^yes
      p|preview "show preview and exit"
    run:
      let hosts = getHosts()
      if hosts.len > 1: fatalQuit "operation only supports one host"
      let run = getLastUpdateRun()
      echo fmt"run created at: {run.created_at}"
      echo "nvd diff:\n", getUpdateSummary(run.id, hosts[0])
      if preview: quit 0
      if not isLocal(): fatalQuit bb"[b]oizys update[/] only supported for local oizys flakes"
      if dirExists(getFlake() / ".jj"): fatalQuit bb"[b]oizys update[/] does not support jujustu repos yet"
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
      c|cache(seq[string], "url of nix binary cache, can be repeated")
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
      if not isLocal():
        quit "`oizys lock` should be run with a local flake"

      newCommand("nix")
        .withArgs("flake", "lock", getFlake())
        .run()

      let lockfile = getFlake() / "flake.lock"
      newCommand("jq").withArgs(".nodes | keys[] | select(contains(\"_\"))", "-r", lockFile).runQuit()

