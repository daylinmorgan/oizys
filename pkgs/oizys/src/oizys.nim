## nix begat oizys
import std/[os, osproc, sequtils, strutils, strtabs, strformat]
import hwylterm, hwylterm/[hwylcli]
import oizys/[context, github, nix, logging, lib, exec]

setHwylConsoleFile(stderr)

if findExe("nix") == "":
  fatalQuit "oizys requires nix"

proc prepGhaInputs(inputs: seq[KVString]): StringTableRef =
  result = newStringTable()
  for (k, v) in inputs:
    if not v.startsWith("@"):
      result[k] = v
    else:
      let fname = v[1..^1]
      if not fileExists(fname):
        hwylCliError("expected file at: " & fname)
      result[k] = readFile(fname)

proc `$`(_: typedesc[string]): string = "str"
proc `$`[T](_: typedesc[seq[T]]): string = $T & "..."
proc `$`(_: typedesc[seq[KVString]]): string = "(key:val)..."

hwylCli:
  name "oizys"
  settings InferEnv, LongHelp
  help:
    styles: fromBuiltinHelpStyles(AllSettings)
  flags:
    [global]
    flake(string, "path/to/flake")
    host(seq[string], "host(s) to build")
    v|verbose(Count(val:0), Count, "increase verbosity (up to 2)")
    `reset-cache`("set cache timeout to 0")
    b|bootstrap("enable bootstrap mode")

    [output]
    m|minimal "get [i]minimal[/] package set"
    s|system "show system path"
    lix "get lix and lix dependents"

    [build]
    `no-nom` "don't use nom"

    # ["_misc"]
    # y|yes "skip all confirmation prompts"
  preSub:
    setupLoggers()
    updateContext(host, flake, verbose, `reset-cache`, bootstrap)

  subcommands:
    [status]
    ... "check oizys package status"
    flags:
      all "show all oizys packages"
      `check-cache` "check configured substituters"
      hide "hide ignored packages"
    run:
      oizysStatus(all, `check-cache`, hide)

    [build]
    ... """
    nix build

    output flags will inject additional positional args
    """
    alias b
    positionals:
      args seq[string]
    flags:
      ^[output]
      ^[build]
    run:
      if minimal:
        debug "populating args with derivations not built/cached"
        args.add getMinimalDrvs()
      if system:
        debug "populating args nixos system.path"
        args.add nixosAttrs("path")
      if lix:
        debug "populating args with lix and lix-dependents"
        args.add getLixandCo().fmtDrvsForNix()
      nixBuild(`no-nom`, args)

    [ci]
    ... "builtin ci"
    subcommands:
      [update]
      ... "build current and updated hosts"
      positionals:
        args seq[string]
      run:
        ciUpdate(args)

      [cache]
      ... "build and push store paths"
      positionals:
        args seq[string]
      flags:
        name("oizys", string, "name/host of binary cache")
        service("attic", string, "name of cache service")
        j|jobs(countProcessors(),int, "jobs when pushing paths")
        n|`dry-run` "don't actually build derivations"
        packages(seq[string], "packages to ensure built/cached")
      run:
        if findExe("nix-eval-jobs") == "":
          fatalQuit bb"[b]oizys cache[/] requires [b]nix-eval-jobs[/]"
        nixBuildWithCache(name, args, service, jobs, `dry-run`, packages)



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
      `open`("open successfully dispatched workflow")
    run:
      let inputs = prepGhaInputs(inputs)
      createDispatch(workflow, `ref`, inputs, open)

    [dry]
    ... "dry run build"
    positionals:
      args seq[string]
    flags:
      ^[output]
    run:
      nixBuildHostDry(minimal, args)

    [os]
    ... "nixos-rebuild [italic]subcmd[/]"
    positionals:
      subcmd NixosRebuildSubcmd
      args seq[string]
    flags:
      r|remote "host is remote"
      ^[build]
    run:
      if nixosRebuild(subcmd, args, remote) != 0:
        fatalQuit fmt"nixos-rebuild {subcmd} failed"
      if subcmd in {switch, boot}:
        quit chezmoiStatus()

    [switch]
    ... "switch to new nixos configuration"
    positionals:
      args seq[string]
    flags:
      ^[build]
    run:
      if not `no-nom`:
        let attrs = nixosAttrs("path")
        debug fmt"pre-building {attrs}"
        let cmd =
          newNixCommand("build", `no-nom`)
            .withArgs(attrs)
            .withArgs("--no-link")
            .withArgs(args)
        if not cmd.runOk:
          fatalQuit fmt"pre nixos build failed for attr: {attrs}"
      let (output, code) = newNixCommand("build", `no-nom`)
        .withArgs(nixosAttrs())
        .withArgs("--print-out-paths", "--no-link")
        .withArgs(args)
        .runCaptStdout()
      if code != 0:
        fatalQuit "failed to build system: " & output

      newCommand("sudo")
        .withArgs(output.strip() / "bin" / "switch-to-configuration")
        .withArgs("switch")
        .runQuit()

    [output]
    ... "nixos config attr"
    alias o
    flags:
      ^[output]
    run:
      if count([minimal, system, lix], true) > 1:
        hecho "--minimal, --system and --lix are mutually exclusive"

      if lix:
        echo getLixandCo().fmtDrvsForNix().join("\n")
      elif minimal:
        echo missingDrvNixEvalJobs().fmtDrvsForNix().join("\n")
      else:
        echo nixosAttrs(
          if system: "path"
          else: "build.toplevel"
        ).join("\n")

#[
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
]#

    [hash]
    ... "collect build hash from failure"
    positionals:
      installable string
    flags:
      `no-copy` "don't copy to clipboard"
    run:
      let hash = getBuildHash(installable)
      stdout.write hash
      if not `no-copy`:
        if newCommand("wl-copy").withArgs(hash).runOk():
          hecho "copied to clipboard!"
        else:
          hecho bb"[red]error[/]: failed to copy to clipboard with wl-copy"

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
    check lock file for duplicates and inputs which should be null
    """
    flags:
      null:
        ? "inputs that should always be null"
        T seq[string]
        * @["flake-compat"]
    run:
      if not isLocal():
        quit "`oizys lock` should be run with a local flake"

      checkFlakeLockFile(null)

    [pr]
    ... """check merge status of nixpkgs PR"""
    flags:
      n|numbers(seq[int], "prs to check")
      ignore("don't check lib/data.nix")
    run:
      if not ignore:
        getNixpkgsPrStatusFromOizys()
      for n in numbers:
        hecho bb(getNixpkgsPrStatus(n))

