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



func makeSubFlags(): seq[string] =
  const substituters {.strdefine.} = ""
  const trustedPublicKeys {.strdefine.} = ""
  if substituters != "":
    result.add "--substituters"
    result.add substituters
  if trustedPublicKeys != "":
    result.add "--trusted-public-keys"
    result.add trustedPublicKeys

const subFlags = makeSubFlags()

proc newNixCommand*(subcmd: string, noNom: bool = false): Command =
  if not noNom:
    if findExe("nom") == "":
      warn "nom not found, falling back to nix"
      result.exe = "nix"
    else:
      result.exe = "nom"
  else:
    result.exe = "nix"

  result.addArgs subcmd
  if isResetCache():
    result.addArgs "--narinfo-cache-negative-ttl", "0"
  if not (not noNom or isCi()):
    result.addArgs "--log-format", "multiline"
  if isBootstrap():
    result.addArgs subFlags

proc nixosAttr(host: string, attr: string = "build.toplevel"): string =
  getFlake() & "#nixosConfigurations." & host & ".config.system." & attr

proc nixosAttrs*(
  attr: string = "build.toplevel"
): seq[string] =
  for host in getHosts():
    result.add nixosAttr(host, attr)

proc newRebuildCommand(subcmd: NixosRebuildSubcmd, args: openArray[string], remote: bool): Command =
  if not remote:
    result.exe = "sudo"
    result.addArgs "nixos-rebuild"
  else:
    result.exe = "nixos-rebuild"

  result.addArgs $subcmd
  result.addArgs "--flake", getFlake()
  result.addArgs "--log-format", "multiline"
  if remote:
    let host = getHosts()[0]
    if host == currentHost:
      fatalQuit "did you mean to specify a remote host?"
    result.addArgs "--target-host", host, "--use-remote-sudo"
  result.addArgs args


proc nixosRebuild*(subcmd: NixosRebuildSubcmd, args: openArray[string] = [], remote: bool = false) =
  if getHosts().len > 1: fatalQuit bb"[bold]oizys os[/] only supports one host"
  let cmd = newRebuildCommand(subcmd, args, remote)
  cmd.runQuit()

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
  result.name = s[^1].replace(".drv", "")

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
    s[0 .. (limit - 4)] & "..."

proc display(msg: string, drvs: seq[DrvPath]) =
  hecho fmt"{msg}: [bold cyan]{drvs.len()}[/]".bb
  if drvs.len > 0:
    let maxLen = min(max drvs.mapIt(it.name.len), 40)
    for drv in drvs:
      hecho "  ", drv.name.trunc(maxLen).alignLeft(maxLen), " ", drv.hash.bb("faint")

proc display(output: DryRunOutput) =
  if getVerbosity() > 0:
    display("to fetch", output.toFetch)
  else:
    hecho fmt"to fetch: [bold cyan]{output.toFetch.len()}[/]".bb
  display("to build", output.toBuild)

# here a results var would be nice...
proc narHash*(s: string): string =
  ## get hash from nix store path
  if not s.startsWith("/nix/store/") and s.len >= 44:
    fatalQuit "failed to extract narHash from: " & s
  let ss = s.split("-")
  result = ss[0].split("/")[^1]

proc nixDerivationShow*(drvs: openArray[string], recursive = false): Table[string, NixDerivation] =
  var cmd = newCommand("nix")
    .withArgs("derivation", "show")
    .withArgs(drvs)
  if recursive:
    cmd = cmd.withArgs("--recursive")
  let (output, _ ) =
    cmd.runCaptSpin("evaluating " & drvs.join(" "))
  fromJson(output, Table[string, NixDerivation])

proc getSystemPathDrvs*(): seq[string] =
  for drvName, _ in nixDerivationShow(nixosAttrs("path")):
    result.add drvName

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

  result = collect:
    for k, drv in nixDerivationShow(systemPathDrvs):
      for inputDrv, _ in drv.inputDrvs:
        inputDrv

proc missingDrvNixEvalJobs*(): HashSet[NixEvalOutput] =
  ## get all derivations not cached using nix-eval-jobs
  var cmd = newCommand("nix-eval-jobs", "--flake", "--check-cache-status")
  var output: string

  for host in getHosts():
    let flakeUrl = getFlake() & "#nixosConfigurations." & host & ".config.oizys.packages"
    let (o, _) = cmd
      .withArgs(flakeUrl)
      .runCaptSpin(bb"running [b]nix-eval-jobs[/] for " & host.bb("bold"))
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

func fmtDrvsForNix*(drvs: HashSet[NixEvalOutput]): seq[string] {.inline.} =
  drvs.mapIt(it.drvPath & "^*")

func fmtDrvsForNix*(drvs: seq[NixEvalOutput]): seq[string] {.inline.} =
  drvs.mapIt(it.drvPath & "^*")

func fmtDrvsForNix*(drvs: seq[string]): seq[string] {.inline.} =
  drvs.mapIt(it & "^*")

func fmtDrvsForNix*(drvs: Table[string, NixDerivation]): seq[string] {.inline.} =
  collect:
    for k, _ in drvs:
      k & "^*"

func splitDrv(drv: string): tuple[name, hash: string] =
  assert drv.startsWith("/nix/store"), "is this a /nix/store path? $1" % [drv]
  let s = drv.split("-", 1)
  (s[1].replace(".drv", ""), s[0].split("/")[^1])

func isLixDependent(drv: NixDerivation): bool =
  # these are some false positives we don't need to build/cache
  if drv.name.startsWith("system-path") or drv.name.startsWith("lazy-options") or drv.name.startsWith("nixos-rebuild-ng"):
    return false
  for drvName, _ in drv.inputDrvs:
    let (name, _) = splitDrv drvName
    if name.startswith("lix-"):
      return true

func isLix(drv: NixDerivation): bool =
  ## is it a lix derivation, disregarding 'lix-<hash>-{dev,debug}'
  if drv.name.startswith("lix-"):
    return not (
      drv.name.endsWith("-debug") or drv.name.endsWith("-dev")
    )

proc getLixAndCo*(): seq[string] =
  ## using `nix derivation show` output, generate a list of all
  ## the derivations which depend on lix
  ##
  ## this is primarily used so that a CI step doesn't need to be manually updated

  for drvName, drv in nixDerivationShow(nixosAttrs("path"), recursive = true):
    if isLix(drv) or isLixDependent(drv):
      result.add drvName

proc nixBuild*(minimal: bool, noNom: bool, rest: seq[string]) =
  var cmd = newNixCommand("build", noNom)
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = missingDrvNixEvalJobs()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs.fmtDrvsForNix()
    cmd.addArgs "--no-link"
  cmd.addArgs rest
  cmd.runQuit()

proc nixBuildHostDry*(minimal: bool, rest: seq[string]) =
  var cmd = newNixCommand("build", noNom = true)
  if minimal:
    debug "populating args with derivations not built/cached"
    let drvs = missingDrvNixEvalJobs()
    if drvs.len == 0:
      info "nothing to build"
      quit "exiting...", QuitSuccess
    cmd.addArgs drvs.fmtDrvsForNix()
    cmd.addArgs "--no-link"
  else:
    cmd.addArgs nixosAttrs()
  cmd.addArgs "--dry-run"
  cmd.addArgs rest
  let (_, err) = cmd
      .runCaptSpin(
      "evaluating derivation for: " & getHosts().join(" ").bb("bold"),
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
  var cmd: Command
  case cache.kind
  of Service:
    cmd.exe = cache.exe
    cmd.addArgs "push", cache.name, "--jobs", $jobs
    cmd.addArgs paths
  of Store:
    cmd.exe = "nix-copy-closure"
    cmd.addArgs "-s", cache.host
    cmd.addArgs paths

  let pushErr = cmd.run()
  if pushErr != 0:
    fatalQuit "failed to push build to cache"


proc build(drv: NixEvalOutput, rest: seq[string]): BuildResult =
  let startTime = now()
  let cmd = newCommand("nix", "build")
    .withArgs(drv.drvPath & "^*", "--no-link")
    .withArgs(rest)

  let (stdout, stderr, buildCode) =
    if "-L" in rest or "--print-build-logs" in rest: ("","", cmd.run())
    else: cmd.runCapt()

  result.duration = now() - startTime

  if buildCode == 0:
    result.successful = true
    info "succesfully built: " & drv.name
  else:
    error "failed to build: " & drv.name
    error "\n" & formatStdoutStderr(stdout, stderr)

  info "-> duration: " & formatDuration(result.duration)

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

  var prettyDrvList: seq[BbString]
  for drv in missing:
    if "out" in drv.outputs:
      prettyDrvList.add prettyDerivation(drv.outputs["out"])
    else:
      error $drv.name, "does not have an 'out' attribute?\n" & "derivation: " & $drv

  info "derivations:\n" & prettyDrvList.join("\n")

  if dry:
    quit "exiting...", QuitSuccess

  let results = collect:
    for drv in missing:
      (drv, build(drv, rest))
 
  var
    outs: seq[string]
    failures: int

  for (drv, res) in results:
    if res.successful:
      outs &= drv.outputs.values.toSeq
    else:
      inc failures

  if outs.len > 0:
    pushPathsToCache(cache, outs, jobs)

  if failures > 0:
    fatalQuit fmt"{failures} builds had non-zero exit"

proc getUpdatedLockFile() =
  info "getting updated flake.lock as updated.lock"
  let res = newCommand("git")
    .withArgs("--no-pager","show","origin/flake-lock:flake.lock")
    .runCapt()
  if res.exitCode != 0:
    fatalQuit "failed to fetch updated lock file using git"
  writeFile("updated.lock", res.stdout)

# probably duplicating logic above ¯\_(ツ)_/¯
proc buildSystem(host: string, rest: seq[string]) =
  let cmd = newNixCommand("build")
    .withArgs(nixosAttr(host))
    .withArgs(rest)
  let code = cmd.run()
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

