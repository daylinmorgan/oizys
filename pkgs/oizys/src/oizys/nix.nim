import std/[
  algorithm, json,
  enumerate, os, sequtils, sets, strformat,
  strutils, sugar, logging, tables, times
]
export tables
import hwylterm, hwylterm/logging, jsony

import ./[context, exec]

proc nixCommand*(cmd: string, nom: bool = false): string =
  if nom:
    if findExe("nom") == "":
      fatalQuit "--nom requires nix-output-monitor is installed"
    result = "nom"
  else:
    result = "nix"
  result.addArg cmd
  if isResetCache():
    result.addArg "--narinfo-cache-negative-ttl 0"
  if not (nom or isCi()):
    result.addArg "--log-format multiline"

proc nixosConfigAttr(host: string): string =
  getFlake() & "#nixosConfigurations." & host & ".config.system.build.toplevel"

proc nixosConfigAttrs*(): seq[string] =
  for host in getHosts():
    result.add nixosConfigAttr(host)

type
  NixosRebuildSubcmd* = enum
    switch, boot, test, build, `dry-build`,`dry-activate`, `edit`,
    repl, `build-vm`, `build-vm-with-bootloader`, `list-generations`

proc handleRebuildArgs(subcmd: NixosRebuildSubcmd, args: openArray[string], remote: bool): string =
  if not remote: result.add "sudo"
  result.addArgs "nixos-rebuild"
  result.addArgs $subcmd
  result.addArgs "--flake", getFlake()
  result.addArgs "--log-format multiline"
  if remote:
    let host = getHosts()[0]
    if host == currentHost:
      fatalQuit "did you mean to specify a remote host?"
    result.addArgs "--target-host", host, "--use-remote-sudo"
    result.addArgs args[1..^1]


proc nixosRebuild*(subcmd: NixosRebuildSubcmd, args: openArray[string] = [], remote: bool = false) =
  if getHosts().len > 1: fatalQuit bb"[bold]oizys os[/] only supports one host"
  let cmd = handleRebuildArgs(subcmd, args, remote)
  quitWithCmd cmd

type
  DrvPath = object
    path*, hash*, name*: string

  DryRunOutput = object
    toBuild: seq[DrvPath]
    toFetch: seq[DrvPath]

func toDerivation*(pkg: string): DrvPath =
  let path = pkg.strip()
  let s = path.split("-", 1)
  result.path = path
  result.hash = s[0].rsplit("/")[^1]
  result.name = s[^1].replace(".drv","")

func toDerivations(lines: seq[string]): seq[DrvPath] =
  for pkg in lines:
    result.add (toDerivation pkg)

proc cmpDrv(x, y: DrvPath): int = 
  cmp(x.name, y.name)

proc parseDryRunOutput(err: string): DryRunOutput =
  debug "parsing result of dry run"
  let lines = err.strip().splitLines()
  let theseLines = collect:
    for i, line in enumerate(lines):
      if line.startswith("these") or line.startswith("this"): i

  case theseLines.len:
    of 2:
      let (firstIdx, secondIdx) = (theseLines[0], theseLines[1])
      result.toBuild = lines[(firstIdx + 1) .. (secondIdx - 1)].toDerivations()
      result.toFetch = lines[(secondIdx + 1) .. ^1].toDerivations()
    of 1:
      let idx = theseLines[0]
      let line = lines[idx]
      let drvs = lines[idx + 1 .. ^1].toDerivations()
      if line.contains("built:"):
        result.toBuild = drvs
      elif line.contains("will be fetched"):
        result.toFetch = drvs
      else:
        fatal """expected at least one of the lines to contain "built" or "fetched", check the output below"""
        stderr.writeLine err
        quit()
    of 0:
      info "nothing to do"
      quit QuitSuccess
    else:
      fatal "unexpected output from nix"
      stderr.writeLine err
      quit()

  result.toBuild.sort(cmpDrv)
  result.toFetch.sort(cmpDrv)

proc trunc*(s: string, limit: int): string =
  if s.len <= limit:
    s
  else:
    s[0..(limit-4)] & "..."

proc display(msg: string, drvs: seq[DrvPath]) =
  echo fmt"{msg}: [bold cyan]{drvs.len()}[/]".bb
  if drvs.len > 0:
    let maxLen = min(max drvs.mapIt(it.name.len), 40)
    for drv in drvs:
      echo "  ", drv.name.trunc(maxLen).alignLeft(maxLen), " ", drv.hash.bb("faint")

proc display(output: DryRunOutput) =
  if getVerbosity() > 0:
    display("to fetch", output.toFetch)
  else:
    echo fmt"to fetch: [bold cyan]{output.toFetch.len()}[/]".bb
  display("to build", output.toBuild)

proc toBuildNixosConfiguration(): seq[string] =
  var cmd = nixCommand("build")
  cmd.addArg "--dry-run"
  cmd.addArgs nixosConfigAttrs()
  let (_, err) = runCmdCaptWithSpinner(
    cmd,
    "running dry run build for: " & (getHosts().join(" ").bb("bold")),
    capture = {CaptStderr}
  )
  let output = parseDryRunOutput err
  return output.toBuild.mapIt(it.path)

type
  DerivationOutput = object
    path*: string
    # hashAlgo: string
    # hash: string
  NixDerivation = object
    inputDrvs*: Table[string, JsonNode]
    name*: string
    outputs*: Table[string, DerivationOutput]

# here a results var would be nice...
proc narHash*(s: string): string =
  ## get hash from nix store path
  if not s.startsWith("/nix/store/") and s.len >= 44:
    fatalQuit "failed to extract narHash from: " &  s
  let ss = s.split("-")
  result = ss[0].split("/")[^1]

proc evaluateDerivations(drvs: openArray[string]): Table[string, NixDerivation] =
  var cmd = "nix derivation show -r"
  cmd.addArgs drvs
  let (output, _) =
    runCmdCaptWithSpinner(cmd, "evaluating derivations")
  fromJson(output, Table[string, NixDerivation])

proc nixDerivationShow*(drvs: openArray[string]): Table[string, NixDerivation] =
  var cmd = "nix derivation show"
  cmd.addArgs drvs
  let (output, _ ) =
    runCmdCaptWithSpinner(cmd, "evaluating " & drvs.join(" "))
  fromJson(output, Table[string, NixDerivation])

# TODO: replace asserts in this proc, would be easier with results type
proc findSystemPaths(drvs: Table[string, NixDerivation]): seq[string] =
  let hosts = getHosts()
  let systemDrvs = collect(
    for k in drvs.keys():
      if k.split("-",1)[1].startswith("nixos-system-"): k
  )

  assert len(hosts) == len(systemDrvs)
  for name in systemDrvs:
    for drv in drvs[name].inputDrvs.keys():
      if drv.endsWith("system-path.drv"):
        result.add drv

  assert len(hosts) == len(result)


proc filterSeq(
  drvs: seq[string],
  filter: proc(s: string): bool,
): tuple[yes: seq[string], no: seq[string]] =
  for drv in drvs:
    if filter(drv): result.yes.add drv
    else: result.no.add drv

func getIgnoredPackages(): seq[string] =
  for l in slurp("ignored.txt").strip().splitLines():
    if not l.startsWith("#"):
      result.add l

func isIgnored(drv: string): bool =
  const ignoredPackages = getIgnoredPackages()
  let name = drv.split("-", 1)[1].replace(".drv","")
  result = name in ignoredPackages
  if not result:
    for pkg in ignoredPackages:
      if name.startswith(pkg):
        return true

proc getSystemPathDrvs*(): seq[string] =
  let systemDrvs = nixDerivationShow(nixosConfigAttrs())
  let systemPathDrvs = findSystemPaths(systemDrvs)
  result =
    collect:
      for k, drv in nixDerivationShow(systemPathDrvs):
        for inputDrv, _ in drv.inputDrvs:
          inputDrv

proc getOizysDerivations():Table[string, NixDerivation] =
  let
    toBuildDrvs = toBuildNixosConfiguration()
    systemPathDrvs = getSystemPathDrvs()
    toActullyBuildDrvs = systemPathDrvs.filterIt(it in toBuildDrvs and not isIgnored(it))
  for path , drv in nixDerivationShow(toActullyBuildDrvs):
    result[path] = drv

proc showOizysDerivations*() =
  let drvs = getOizysDerivations()
  for path, drv in drvs:
    echo path & "^*"

# TODO: remove this proc
proc systemPathDrvsToBuild*(): seq[string] =
  var inputDrvs, dropped: seq[string]
  let toBuild = toBuildNixosConfiguration()
  let drvs = evaluateDerivations(nixosConfigAttrs())

  let systemPaths = findSystemPaths(drvs)
  for p in systemPaths:
    inputDrvs &= drvs[p].inputDrvs.keys().toSeq()

  (result, _) = filterSeq(inputDrvs, (s) => s in toBuild)
  (dropped, result) =  filterSeq(result, isIgnored)
  debug fmt"ignored {dropped.len} derivations"
  result = result.mapIt(it & "^*")


func splitDrv(drv: string): tuple[name, hash:string] =
  assert drv.startsWith("/nix/store"), "is this a /nix/store path? $1" % [drv]
  let s = drv.split("-", 1)
  (s[1].replace(".drv",""),s[0].split("/")[^1])

proc writeDervationsToStepSummary(drvs: seq[string]) =
  let rows = collect(
    for drv in drvs:
      let (name,hash) = splitDrv(drv)
      fmt"| {name} | `{hash}` |"
  )
  let summaryFilePath = getEnv("GITHUB_STEP_SUMMARY")
  if summaryFilePath == "": fatalQuit "no github step summary found"
  let output = open(summaryFilePath,fmAppend)
  output.writeLine("| derivation | hash |\n|---|---|")
  output.writeLine(rows.join("\n"))
  close output

proc nixBuild*(minimal: bool, nom: bool, rest: seq[string]) =
  var cmd = nixCommand("build", nom)
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = systemPathDrvsToBuild()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs
    cmd.addArg "--no-link"
    if isCi():
      writeDervationsToStepSummary drvs
  cmd.addArgs rest
  quitWithCmd cmd


proc nixBuildHostDry*(minimal: bool, rest: seq[string]) =
  var cmd = nixCommand("build")
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = systemPathDrvsToBuild()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs
    cmd.addArg "--no-link"

    if isCi():
      writeDervationsToStepSummary drvs
  else:
    cmd.addArgs nixosConfigAttrs()

  cmd.addArg "--dry-run"
  cmd.addArgs rest
  let (_, err) =
    runCmdCaptWithSpinner(
      cmd,
      "evaluating derivation for: " & getHosts().join(" ").bb("bold"),
      {CaptStderr}
    )
  let output = parseDryRunOutput err
  display output


type
  BuildResult = object
    duration*: Duration
    successful*: bool

func formatDuration(d: Duration): string =
  ## convert duration to: X minutes and Y seconds
  let seconds = d.inSeconds
  if seconds > 60:
    result.add $(seconds div 60) & " minutes"
    result.add " and "
  result.add $(seconds mod 60) & " seconds"

# TODO: by default collect the build result
proc build(path: string, drv: NixDerivation, rest: seq[string]): BuildResult =
  let startTime = now()
  var cmd = "nix build"
  cmd.addArgs path & "^*", "--no-link"
  cmd.addArgs rest

  let (stdout, stderr, buildCode) =
    if "-L" in rest or "--print-build-logs" in rest: ("","", runCmd(cmd))
    else: runCmdCapt(cmd, {CaptStderr})

  result.duration = now() - startTime

  # result.stdout = stdout
  # result.stderr = stderr
  if buildCode == 0:
    result.successful = true
    info "succesfully built: " & splitDrv(path).name
  else:
    error "failed to build: " & splitDrv(path).name
    error "\n" & formatStdoutStderr(stdout, stderr)

  info "-> duration: " & formatDuration(result.duration)

func outputsPaths(drv: NixDerivation): seq[string] =
  for _, output in drv.outputs:
    result.add output.path

proc reportResults(results: seq[(string, NixDerivation, BuildResult)]) =
  let rows = collect(
    for (path, drv, res) in results:
      let (name, hash) = splitDrv(path)
      fmt"| {name} | `{hash}` | " & (
        if res.successful: ":white_check_mark:"
        else: ":x:"
      ) & " |" & $(res.duration)
  )
  let summaryFilePath = getEnv("GITHUB_STEP_SUMMARY")
  if summaryFilePath == "": fatalQuit "no github step summary found"
  let output = open(summaryFilePath, fmAppend)
  output.writeLine "| derivation | hash | build | time |"
  output.writeLine "|---|---|---|---|"
  output.writeLine rows.join("\n")
  close output


proc prettyDerivation*(path: string): BbString =
  const maxLen = 40
  let drv = path.toDerivation()
  drv.name.trunc(maxLen) & " " & drv.hash.bb("faint")


proc nixBuildWithCache*(name: string, rest: seq[string], service: string, jobs: int, dry: bool) =
  ## build individual derivations not cached and push to cache

  if findExe(service) == "": fatalQuit fmt"is {service} installed?"
  info bbfmt"building and pushing to cache: [b]{name}"
  debug "determining missing cache hits"

  let drvs = getOizysDerivations()
  if drvs.len == 0:
    info "nothing to build"
    quit "exiting...", QuitSuccess

  # TODO: fix this so it works with table
  # info fmt("need to build {drvs.len} derivations:\n") & drvs.mapIt(prettyDerivation("  " & it.outputs["out"].path)).join("\n")

  info fmt("need to build {drvs.len} dervations")
  for _, drv in drvs:
    info prettyDerivation(drv.outputs["out"].path)

  if dry:
    quit "exiting...", QuitSuccess

  let results =
    collect:
      for path, drv in drvs:
        (path, drv, build(path, drv, rest))

  var outs: seq[string]
  for (path, drv, res) in results:
    if res.successful:
      outs &= drv.outputsPaths

  if isCi():
    reportResults(results)

  if outs.len > 0:
    # TODO: push after build not at once?
    var cmd = service
    cmd.addArg "push"
    cmd.addArg name
    cmd.addArg "--jobs"
    cmd.addArg $jobs
    cmd.addArgs outs
    let pushErr = runCmd(cmd)
    if pushErr != 0:
      errorQuit "failed to push build to cache"

proc getUpdatedLockFile() =
  info "getting updated flake.lock as updated.lock"
  let res = runCmdCapt("git --no-pager show origin/flake-lock:flake.lock")
  if res.exitCode != 0:
    fatalQuit "failed to fetch updated lock file using git"
  writeFile("updated.lock", res.stdout)

# probably duplicating logic above ¯\_(ツ)_/¯
proc buildSystem(host: string, rest: seq[string]) =
  var cmd = nixCommand("build")
  cmd.addArg nixosConfigAttr(host)
  cmd.addArgs rest
  let code = runCmd cmd
  if code != 0:
    fatalQuit "build failed"

proc ciUpdate*(rest: seq[string]) =
  for host in getHosts():
    info "building " & host.bb("bold")
    buildSystem(
      host,
      @["--out-link", host & "-current", "--quiet"] & rest
    )

  getUpdatedLockFile()

  for host in getHosts():
    info "building updated " & host.bb("bold")
    buildSystem(
      host,
      @["--out-link", host & "-updated", "--quiet", "--reference-lock-file", "updated.lock"] & rest
    )

