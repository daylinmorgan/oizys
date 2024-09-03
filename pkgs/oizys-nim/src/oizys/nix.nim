import std/[
  algorithm, json,
  enumerate, os, osproc, sequtils, strformat,
  strutils, sugar, logging, tables
]
import bbansi, jsony
import ./[context, exec]


proc nixCommand(cmd: string): string =
  result = "nix"
  if isResetCache():
    result.addArg "--narinfo-cache-negative-ttl 0"
  result.addArg "--log-format multiline"
  result.addArg cmd

proc nixosConfigAttrs*(): seq[string] =
  for host in getHosts():
    result.add fmt"{getFlake()}#nixosConfigurations.{host}.config.system.build.toplevel"

const nixosSubcmds* =
  """switch boot test build dry-build dry-activate edit
  repl build-vm build-vm-with-bootloader list-generations""".splitWhitespace()

proc nixosRebuild*(subcmd: string, rest: seq[string] = @[]) =
  var cmd = fmt"sudo nixos-rebuild {subcmd} --flake {getFlake()} --log-format multiline"
  if getHosts().len > 1:
    error "nixos-rebuild only supports one host"
    quit QuitFailure
  cmd.addArgs rest
  quitWithCmd cmd

type
  Derivation = object
    storePath, hash, name: string

  DryRunOutput = object
    toBuild: seq[Derivation]
    toFetch: seq[Derivation]

func toDerivation(pkg: string): Derivation =
  let path = pkg.strip()
  let s = path.split("-", 1)
  result.storePath = path
  result.hash = s[0].rsplit("/")[^1]
  result.name = s[^1].replace(".drv","")

func toDerivations(lines: seq[string]): seq[Derivation] =
  for pkg in lines:
    result.add (toDerivation pkg)

proc cmpDrv(x, y: Derivation): int = 
  cmp(x.name, y.name)

proc parseDryRunOutput(err: string): DryRunOutput =
  let lines = err.strip().splitLines()
  let theseLines = collect:
    for i, line in enumerate(lines):
      if line.startswith("these"): i

  case theseLines.len:
    of 2:
      let (firstIdx, secondIdx) = (theseLines[0], theseLines[1])
      result.toBuild = lines[(firstIdx + 1) .. (secondIdx - 1)].toDerivations()
      result.toFetch = lines[(secondIdx + 1) .. ^1].toDerivations()
    of 1:
      let idx = theseLines[0]
      let line = lines[idx]
      let drvs = lines[idx .. ^1].toDerivations()
      if line.contains("built:"):
        result.toBuild = drvs
      elif line.contains("will be fetched"):
        result.toFetch =drvs
      else:
        fatal "expected on of the lines to contain built or fetched check the output below"
        stderr.writeLine err
        quit()
    of 0:
      info "nothing to do";
      quit(QuitSuccess)
    else:
      fatal "unexpected output from nix"
      stderr.writeLine err
      quit()

  result.toBuild.sort(cmpDrv)
  result.toFetch.sort(cmpDrv)

proc trunc(s: string, limit: int): string =
  if s.len <= limit: 
    s
  else:
    s[0..(limit-4)] & "..."

proc display(msg: string, drvs: seq[Derivation]) =
  echo fmt"{msg}: [bold cyan]{drvs.len()}[/]".bb
  let maxLen = min(max drvs.mapIt(it.name.len), 40)
  for drv in drvs:
    echo "  ", drv.name.trunc(maxLen).alignLeft(maxLen), " ", drv.hash.bb("faint")

proc display(output: DryRunOutput) = 
  if isDebug():
    display("to fetch", output.toFetch)
  else:
    echo fmt"to fetch: [bold cyan]{output.toFetch.len()}[/]".bb
  display("to build", output.toBuild)

proc toBuildNixosConfiguration(): seq[string] =
  var cmd = nixCommand("build")
  cmd.addArg "--dry-run"
  cmd.addArgs nixosConfigAttrs()
  let (_, err) = runCmdCaptWithSpinner(cmd, "running dry run build for: " & getHosts().join(" "))
  let output = parseDryRunOutput err
  return output.toBuild.mapIt(it.storePath)

type
  NixDerivation = object
    inputDrvs: Table[string, JsonNode]
    name: string

proc evaluateDerivations(drvs: seq[string]): Table[string,NixDerivation] =
  var cmd = "nix derivation show -r"
  cmd.addArgs drvs
  let (output, _) =
    runCmdCaptWithSpinner(cmd, "evaluating derivations")
  output.fromJson(Table[string,NixDerivation])


# TODO: replace asserts in this proc
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

func isIgnored(drv: string): bool =
  const ignoredPackages = (slurp "ignored.txt").splitLines()
  drv.split("-", 1)[1].replace(".drv","") in ignoredPackages

proc systemPathDrvsToBuild(): seq[string] =
  let toBuild = toBuildNixosConfiguration()
  let drvs = evaluateDerivations(nixosConfigAttrs())
  let systemPaths = findSystemPaths(drvs)
  var inputDrvs: seq[string]
  for p in systemPaths:
    inputDrvs &= drvs[p].inputDrvs.keys().toSeq()
  result = collect(
    for drv in inputDrvs:
      if (drv in toBuild) and (not drv.isIgnored()):
        drv & "^*"
  )

func splitDrv(drv: string): tuple[name, hash:string] =
  let s = drv.split("-", 1)
  (s[1].replace(".drv^*",""),s[0].split("/")[^1])

proc writeDervationsToStepSummary(drvs: seq[string]) =
  let rows = collect(
    for drv in drvs:
      let (name,hash) = splitDrv(drv)
      fmt"| {name} | {hash} |"
  )
  let summaryFilePath = getEnv("GITHUB_STEP_SUMMARY")
  if summaryFilePath == "":
    fatal "no github step summary found"
    quit QuitFailure
  let output = open(summaryFilePath,fmAppend)
  output.writeLine("| derivation | hash |\n|---|---|")
  output.writeLine(rows.join("\n"))

proc nixBuild*(minimal: bool, rest: seq[string]) = 
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
    runCmdCaptWithSpinner(cmd, "evaluating derivation for: " & getHosts().join(" "))
  let output = parseDryRunOutput err
  display output

