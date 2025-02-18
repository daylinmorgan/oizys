import std/[
  algorithm, json, enumerate,
  os, sequtils, strformat, strutils,
  sugar, logging, tables, times, sets
]
export tables
import hwylterm, hwylterm/logging, jsony

import ./[context, exec]

type
  Substituters = object
    `extra-substituters`: seq[string]
    `extra-trusted-public-keys`: seq[string]

  NixosRebuildSubcmd* = enum
    switch, boot, test, build, `dry-build`,`dry-activate`, `edit`,
    repl, `build-vm`, `build-vm-with-bootloader`, `list-generations`

  # should I just convert these to NixDerivation?
  NixEvalOutput = object
    name: string
    drvPath: string
    isCached: bool
    outputs: Table[string, string]

  DerivationOutput = object
    path*: string
    # hashAlgo: string
    # hash: string
  NixDerivation = object
    inputDrvs*: Table[string, JsonNode]
    name*: string
    outputs*: Table[string, DerivationOutput]



# TODO: replace with nim string defines?
func makeSubFlags(): seq[string] =
  let subs = slurp("substituters.json").fromJson(Substituters)
  for k, v in subs.fieldPairs():
    result.add "--" & k
    result.add "\"" & v.join(" ") & "\""

const subFlags = makeSubFlags()

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
  if isBootstrap():
    result.addArgs subFlags

proc nixosAttr(host: string, attr: string = "build.toplevel"): string =
  getFlake() & "#nixosConfigurations." & host & ".config.system." & attr

proc nixosAttrs*(
  attr: string = "build.toplevel"
): seq[string] =
  for host in getHosts():
    result.add nixosAttr(host, attr)

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
  cmd.addArgs nixosAttrs()
  let (_, err) = runCmdCaptWithSpinner(
    cmd,
    "running dry run build for: " & (getHosts().join(" ").bb("bold")),
    capture = {CaptStderr}
  )
  let output = parseDryRunOutput err
  return output.toBuild.mapIt(it.path)

# here a results var would be nice...
proc narHash*(s: string): string =
  ## get hash from nix store path
  if not s.startsWith("/nix/store/") and s.len >= 44:
    fatalQuit "failed to extract narHash from: " &  s
  let ss = s.split("-")
  result = ss[0].split("/")[^1]

# proc evaluateDerivations(drvs: openArray[string]): Table[string, NixDerivation] =
#   var cmd = "nix derivation show -r"
#   cmd.addArgs drvs
#   let (output, _) =
#     runCmdCaptWithSpinner(cmd, "evaluating derivations")
#   fromJson(output, Table[string, NixDerivation])

proc nixDerivationShow*(drvs: openArray[string]): Table[string, NixDerivation] =
  var cmd = "nix derivation show"
  cmd.addArgs drvs
  let (output, _ ) =
    runCmdCaptWithSpinner(cmd, "evaluating " & drvs.join(" "))
  fromJson(output, Table[string, NixDerivation])

proc getSystemPathDrvs*(): seq[string] =
  for drv, _ in nixDerivationShow(nixosAttrs("path")):
    result.add drv

func getIgnoredPackages(): seq[string] =
  for l in slurp("ignored.txt").strip().splitLines():
    if not l.startsWith("#"):
      result.add l

func isIgnored(name: string): bool =
  const ignoredPackages = getIgnoredPackages()
  result = name in ignoredPackages
  if not result:
    for pkg in ignoredPackages:
      if name.startswith(pkg):
        return true

proc getSystemPathInputDrvs*(): seq[string] =
  let systemPathDrvs = getSystemPathDrvs()

  result =
    collect:
      for k, drv in nixDerivationShow(systemPathDrvs):
        for inputDrv, _ in drv.inputDrvs:
          inputDrv

proc missingDrvNixEvalJobs*(): HashSet[NixEvalOutput] =
  ## get all derivations not cached using nix-eval-jobs
  var cmd = "nix-eval-jobs"
  cmd.addArgs "--flake", "--check-cache-status"
  var output: string

  for host in getHosts():
    let (o, _) = runCmdCaptWithSpinner(
      fmt"{cmd} {getFlake()}#hydraJobs.systemPackages.{host}",
      bb"running [b]nix-eval-jobs[/] for system path: " & host.bb("bold")
    )
    output.add o

  var cached: HashSet[NixEvalOutput]
  var ignored: HashSet[NixEvalOutput]

  for line in output.strip().splitLines():
    let output = line.fromJson(NixEvalOutput)
    if output.isCached:
      cached.incl output
    elif output.name.isIgnored():
      ignored.incl output
    else:
      result.incl output

  debug "cached derivations: ", bb($cached.len, "yellow")
  debug "ignored derivations: ", bb($ignored.len, "yellow")

func fmtDrvsForNix*(drvs: HashSet[NixEvalOutput]): string {.inline.} =
  drvs.mapIt(it.drvPath & "^*").join(" ")

func fmtDrvsForNix*(drvs: seq[NixEvalOutput]): string {.inline.} =
  drvs.mapIt(it.drvPath & "^*").join(" ")

func fmtDrvsForNix*(drvs: seq[string]): string {.inline.} =
  drvs.mapIt(it & "^*").join(" ")

func fmtDrvsForNix*(drvs: Table[string, NixDerivation]): string {.inline.} =
  let formatted =
    collect:
      for k, _ in drvs:
        k & "^*"
  formatted.join(" ")

func splitDrv(drv: string): tuple[name, hash:string] =
  assert drv.startsWith("/nix/store"), "is this a /nix/store path? $1" % [drv]
  let s = drv.split("-", 1)
  (s[1].replace(".drv",""),s[0].split("/")[^1])

proc nixBuild*(minimal: bool, nom: bool, rest: seq[string]) =
  var cmd = nixCommand("build", nom)
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = missingDrvNixEvalJobs()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs.fmtDrvsForNix()
    cmd.addArgs "--no-link"
    # if isCi():
    #   writeDervationsToStepSummary drvs
  cmd.addArgs rest
  quitWithCmd cmd

proc nixBuildHostDry*(minimal: bool, rest: seq[string]) =
  var cmd = nixCommand("build")
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = missingDrvNixEvalJobs()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs.fmtDrvsForNix()
    cmd.addArg "--no-link"
  else:
    cmd.addArgs nixosAttrs()
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

# NOTE: two above procs are redundant

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


type NixCacheKind = enum
  Store      ## Nix-serve-ng, Harmonia
  Service    ## Attic, Cachix

type NixCache = object
  case kind: NixCacheKind
  of Store:
    host: string
  of Service:
    exe: string
    name: string


proc toCache(service: string, name: string): NixCache =
  case service
  of "store", "harmonia", "nix-serve-ng":
    info bbfmt"building and pushing to /nix/store/ host: [b]{name}"
    result = NixCache(kind: Store, host: name)
  of "attic", "cachix":
    info bbfmt"building and pushing to {service} cache: [b]{name}"
    if findExe(service) == "":
      fatalQuit fmt"is {service} installed?"
    result = NixCache(kind: Service, name: name, exe: service)
  else:
    fatalQuit fmt"unknown cache service: {service}"

proc pushPathsToCache(cache: NixCache, paths: openArray[string], jobs: int) =
  var cmd: string
  case cache.kind:
  of Service:
    cmd.addArgs cache.exe, "push", cache.name, "--jobs", $jobs
    cmd.addArgs paths
  of Store:
    cmd.addArgs "nix-copy-closure", "-s", cache.host
    cmd.addArgs paths

  let pushErr = runCmd(cmd)
  if pushErr != 0:
    errorQuit "failed to push build to cache"


# TODO: by default collect the build result
proc build(drv: NixEvalOutput, rest: seq[string]): BuildResult =
  let startTime = now()
  var cmd = "nix build"
  cmd.addArgs drv.drvPath & "^*", "--no-link"
  cmd.addArgs rest

  let (stdout, stderr, buildCode) =
    if "-L" in rest or "--print-build-logs" in rest: ("","", runCmd(cmd))
    else: runCmdCapt(cmd, {CaptStderr})

  result.duration = now() - startTime

  if buildCode == 0:
    result.successful = true
    info "succesfully built: " & drv.name
  else:
    error "failed to build: " & drv.name
    error "\n" & formatStdoutStderr(stdout, stderr)

  info "-> duration: " & formatDuration(result.duration)

# func outputsPaths(drv: NixDerivation): seq[string] =
#   for _, output in drv.outputs:
#     result.add output.path

proc reportResults(results: seq[(NixEvalOutput, BuildResult)]) =
  let rows = collect(
    for (drv, res) in results:
      let (name, hash) = splitDrv(drv.drvPath)
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

  let cache = toCache(service, name)
  debug "determining missing cache hits"

  let missing = missingDrvNixEvalJobs()

  info "derivations to build: ", bb($missing.len, "yellow")
  if missing.len == 0:
    quit "exiting...", QuitSuccess

  info "derivations:\n" & missing.mapIt("  " & prettyDerivation(it.outputs["out"])).join("\n")

  if dry:
    quit "exiting...", QuitSuccess

  let results =
    collect:
      for drv in missing:
        (drv, build(drv, rest))

  var outs: seq[string]
  for (drv, res) in results:
    if res.successful:
      outs &= drv.outputs.values.toSeq

  if isCi():
    reportResults(results)

  if outs.len > 0:
    pushPathsToCache(cache, outs, jobs)

proc getUpdatedLockFile() =
  info "getting updated flake.lock as updated.lock"
  let res = runCmdCapt("git --no-pager show origin/flake-lock:flake.lock")
  if res.exitCode != 0:
    fatalQuit "failed to fetch updated lock file using git"
  writeFile("updated.lock", res.stdout)

# probably duplicating logic above ¯\_(ツ)_/¯
proc buildSystem(host: string, rest: seq[string]) =
  var cmd = nixCommand("build")
  cmd.addArg nixosAttr(host)
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

