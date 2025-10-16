import std/[
  sequtils, algorithm,
  strformat, strutils, sugar, sets, os,
  httpclient, terminal, wordwrap
]
import hwylterm, resultz
import ./[nix, exec, logging, context]

# TODO: refactor runCmdCaptWithSpinner so it works in getBuildHash
proc checkBuild(installable: string): tuple[stdout: string, stderr: string] =
  var
    output, err: string
    code: int
  let cmd = newNixCommand("build", noNom=true).withArgs(installable)
  withSpinner(bbfmt"attempt to build: [b]{installable}"):
    (output, err, code) = cmd.runCapt()
  if code == 0:
    fatalQuit fmt"{cmd} had zero exit"
  result = (output, err)

proc getBuildHash*(installable: string): string =
  let (output, err) = checkBuild(installable)
  for line in err.splitLines():
    if line.strip().startsWith("got: "):
      let s = line.split("got:")
      result = s[1].strip()
  if result == "":
    stderr.write formatStdoutStderr(output, err) & "\n"
    fatalQuit "failed to find update hash from above output"

proc getCaches(): seq[string] =
  ## use nix to get the current cache urls
  debug "determing caches to check"
  let (output, _, code) = newCommand("nix", "config", "show").runCapt()
  if code != 0:
    hecho formatSubprocessError(output)
    fatalQuit "error running `nix config show`"

  for line in output.splitLines():
    if line.startsWith("substituters ="):
      let s = line.split("=")[1].strip()
      for u in s.split():
        result.add u.strip(chars = {'/'})

  if result.len == 0:
    hecho formatSubprocessError(output)
    fatalQuit "error running `nix config show`"

proc hasNarinfo*(cache: string, path: string): Opt[string] =
  debug fmt"checking {cache} for {path}"
  let
    hash = narHash(path)
    url = cache & "/" & hash & ".narinfo"

  var client = newHttpClient()
  try:
    let res = client.get(url)
    if res.code == Http200:
      result.ok res.body.strip()
  finally:
    client.close()

proc fmtNarinfo(s: string): BbString =
  let maxWidth = terminalWidth()
  result.add "narinfo:"
  for line in s.splitLines():
    let
      ss = line.split(": ", maxsplit = 1)
      (k, v) = (ss[0], ss[1])
    result.add bbfmt("\n  [b]{k}[/]: ")
    if (len(v) - len(k) + 2) > maxWidth:
      result.add "\n    " & wrapWords(v, maxLineWidth = maxWidth - 2, newLine="\n  ")
    else:
      result.add v

proc searchCaches(caches: seq[string], path: string): Opt[string] =
  ## search all caches until a match is found
  debug "searching for: " & prettyDerivation(path)
  for cache in caches:
    let narinfo = hasNarinfo(cache, path)
    if narinfo.isSome():
      return narinfo

    # case hasNarinfo(cache, path):
    # of Some(narinfo):
    #   info fmt"exists in {cache}"
    #   debug fmtNarinfo(narinfo)
    #
    #   return true
    # of None: discard

proc checkForCache*(installables: seq[string], caches: seq[string]) =
  let caches =
    if caches.len > 0: caches
    else: getCaches()
  let drvs = nixDerivationShow(installables)
  # outputs['outs'] might blow up
  let outs = collect:
    for name, drv in drvs:
      {name: drv.outputs["out"].path}

  for name, path in outs:
    case searchCaches(caches, path)
    of Some(narinfo):
      debug fmtNarinfo(narinfo) # shouldn't a funciton called 'narinfo' give you the narinfo by default?
    of None:
      error "did not find above 'narinfo' in any caches"


proc chezmoiStatus*(): int =
  let cmd = newCommand("chezmoi", "status")
  let (output, err, code) = cmd.runCapt
  if code != 0:
    stderr.write($formatStdoutStderr(output, err) & "\n")
    error fmt"{cmd} had non zero exit"
    return code
  else:
    if output != "":
      info "fyi the dotfiles don't match:"
      hecho output.strip().indent(2)

proc inputDrvNames(drvs: Table[string, NixDerivation]): seq[string] =
  for _, drv in drvs:
    for name, _ in drv.inputDrvs:
      result.add name

proc extractInputDrvs(drvs: Table[string, NixDerivation]): Table[string, NixInputDrv] =
  for _, drv in drvs:
    for name, inputDrv in drv.inputDrvs:
      if name notin result:
        result[name] = inputDrv

type
  NarStatus = enum
    Local, Cached
  OizysPackage = object
    name: string
    outputs: Table[string, Hashset[NarStatus]]
    ignored: bool

  OizysPackages = seq[OizysPackage]

proc newOizysPackage(drv: NixDerivation, inputDrv: NixInputDrv): OizysPackage =
  result.name = drv.name
  if drv.name.isIgnored():
    result.ignored = true
    return
  for output in inputDrv.outputs:
    let k = drv.outputs[output].path
    result.outputs[k] = initHashSet[NarStatus]()

proc checkLocal(p: var OizysPackage) =
  for path, status in p.outputs.mpairs:
    if (path.fileExists() or path.dirExists()):
      status.incl Local

proc checkCaches(p: var OizysPackage, caches: seq[string]) =
  for path, status in p.outputs.mpairs:
    let narinfo = caches.searchCaches(path)
    if narinfo.isSome():
      status.incl Cached

proc getOizysPackages(): OizysPackages =
  let systemPathDrvs = nixDerivationShow(nixosAttrs("path"))
  let systemPathInputDrvs = nixDerivationShow(systemPathDrvs.inputDrvNames())
  let inputDrvs = extractInputDrvs(systemPathDrvs)
  for path, drv in systemPathInputDrvs:
    result.add newOizysPackage(drv, inputDrvs[path])

proc cmp(x, y: OizysPackage): int =
  cmp(x.name, y.name)

func status(p: OizysPackage): HashSet[NarStatus] =
  for s in p.outputs.values():
    result = result + s

proc statusTable(pkgs: OizysPackages, hide = false): Bbstring =
  const width = 30
  let pkgs = pkgs.sorted(cmp)
  result.add "name".alignLeft(width).bb("bold")
  result.add " "
  result.add "status".bb("bold")

  for pkg in pkgs:
    if hide and pkg.ignored: continue

    let name =
      if pkg.name.len > width:
        pkg.name[0..width-4] & "..."
      else:
        pkg.name.alignLeft(width)

    result.add "\n"

    let style =
      if pkg.ignored: "faint"
      elif pkg.status.len == 0: "bold yellow"
      elif Local in pkg.status: ""
      elif Cached in pkg.status: ""
      else: ""
    result.add name.bb(style)
    result.add " "
    result.add pkg.status.toSeq().join(";")


iterator toCheck(pkgs: var OizysPackages): var OizysPackage =
  ## iterate over a mutable subset of packages
  for pkg in pkgs.mitems:
    if not pkg.ignored:
      yield pkg

proc setStatus(pkgs: var OizysPackages, checkCache: bool) =
  let caches = getCaches()
  withSpinner("Checking statuses"):
    if getVerbosity() > 1: spinner.stop # logging interferes with spinner
    for pkg in pkgs.toCheck:
      spinner.setText(fmt"checking status: {pkg.name}")
      pkg.checkLocal()
      if Local notin pkg.status or checkCache:
        spinner.setText(fmt"checking remote status: {pkg.name}")
        pkg.checkCaches(caches)

proc toBuild(pkgs: OizysPackages): seq[OizysPackage] =
  pkgs.filterIt(it.status.len == 0 and not it.ignored)

proc oizysStatus*(all = false, checkCache = false, hide = false) =
  var pkgs = getOizysPackages()

  setStatus pkgs, checkCache

  if all:
    echo statusTable(pkgs, hide)
  else:
    let toBuild = pkgs.toBuild()
    if toBuild.len == 0:
      echo "nothing to build/push :)"
    else:
      echo toBuild.mapIt(it.name).join("\n")


proc toOizysPackage(x: NixEvalOutput): OizysPackage =
  result.name = x.name
  for k, v in x.outputs.pairs:
    result.outputs[v] = initHashSet[NarStatus]() # how to handle isCached
  result.ignored = x.name.isIgnored
  if not result.ignored:
    checkLocal result

    if x.isCached:
      for v in result.outputs.mvalues:
        v.incl Cached
