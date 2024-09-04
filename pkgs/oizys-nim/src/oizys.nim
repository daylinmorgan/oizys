## nix begat oizys
import std/[os, tables, sequtils, strformat,]

import cligen, bbansi
import oizys/[context, github, nix, overlay, logging]


addHandler(
  newFancyConsoleLogger(
    levelThreshold=lvlAll,
    useStderr = true,
    fmtPrefix = $bb"[b magenta]oizys"
  )
)

overlay:
  proc pre(
    flake: string = "",
    host: seq[string] = @[],
    debug: bool = false,
    resetCache: bool = false,
    rest: seq[string],
  ) =
    if not debug: setLogFilter(lvlInfo)
    updateContext(host, flake, debug, resetCache)

  proc dry(minimal: bool = false) =
    ## dry run build
    nixBuildHostDry(minimal, rest)

  proc output(yes: bool = false) =
    ## output
    echo nixosConfigAttrs().join(" ")

  proc update(yes: bool = false) =
    ## *TBI* update and run nixos-rebuild
    fatal "not implemented"

  proc build(minimal: bool = false) =
    ## nix build
    nixBuild(minimal, rest)

  proc cache(minimal: bool = false, name: string = "daylin") =
    ## build and push to cachix
    nixBuildWithCache(minimal, name, rest)

  proc osCmd() =
    ## nixos-rebuild
    if len(rest) == 0: quit "please provide subcmd"
    let subcmd = rest[0]
    if subcmd notin nixosSubcmds:
      error (
        &"unknown nixos-rebuild subcmd: {subcmd}\nexpected one of: \n" &
        nixosSubcmds.mapIt("  " & it).join("\n")
      ); quit QuitFailure
    nixosRebuild(subcmd, rest[1..^1])

  proc ci(`ref`: string = "main") =
    ## trigger GHA update flow
    if rest.len == 0:
      fatal "expected workflow file name"; quit QuitFailure
    createDispatch(rest[0], `ref`)

proc checkExes() =
  if findExe("nix") == "":
    quit("oizys requires nix", QuitFailure)

proc `//`(t1: Table[string, string], t2: Table[string, string]): Table[string, string] =
  # nix style shallow table merge
  for k, v in t1.pairs(): result[k] = v
  for k, v in t2.pairs(): result[k] = v

proc setupCligen() =
  let isColor = getEnv("NO_COLOR") == ""
  if clCfg.useMulti == "":
    clCfg.useMulti =
      if isColor:
        "${doc}\e[1mUsage\e[m:\n  $command {SUBCMD} [sub-command options & parameters]\n\n\e[1msubcommands\e[m:\n$subcmds"
      else:
        "${doc}Usage:\n  $command {SUBCMD} [sub-command options & parameters]\n\nsubcommands:\n$subcmds"
  if not isColor: return
  if clCfg.helpAttr.len == 0:
    clCfg.helpAttr = {"cmd": "\e[1;36m", "clDescrip": "", "clDflVal": "\e[33m",
        "clOptKeys": "\e[32m", "clValType": "\e[31m", "args": "\e[3m"}.toTable()
    clCfg.helpAttrOff = {"cmd": "\e[m", "clDescrip": "\e[m", "clDflVal": "\e[m",
        "clOptKeys": "\e[m", "clValType": "\e[m", "args": "\e[m"}.toTable()
    # clCfg.use  does nothing?
    clCfg.useHdr = "\e[1musage\e[m:\n  "

when isMainModule:
  checkExes()
  setupCligen()
  let (optOpen, optClose) =
    if getEnv("NO_COLOR") == "": ("\e[1m","\e[m")
    else: ("","")
  let
    usage = &"$command [flags]\n$doc{optOpen}Options{optClose}:\n$options"
    osUsage = &"$command [subcmd] [flags]\n$doc{optOpen}Options{optClose}:\n$options"

  const
    sharedHelp = {
      "flake"      : "path/to/flake",
      "host"       : "host(s) to build",
      "debug"      : "enable debug mode",
      "resetCache" : "set cache timeout to 0"
    }.toTable()
    updateHelp = {
      "yes"        : "skip all confirmation prompts"
    }.toTable() // sharedHelp
    ciHelp = {
      "ref"        : "git ref/branch/tag to trigger workflow on"
    }.toTable()
    cacheHelp = {
      "name"       : "name of cachix binary cache"
    }.toTable() // sharedHelp

  # setting clCfg.use wasn't working?
  dispatchMulti(
    [build,  help = sharedHelp, usage = usage],
    [cache,  help = cacheHelp,  usage = usage],
    [ci,     help = ciHelp,     usage = usage],
    [dry,    help = sharedHelp, usage = usage],
    [osCmd,  help = sharedHelp, usage = osUsage, cmdName = "os"],
    [output, help = sharedHelp, usage = usage],
    [update, help = updateHelp, usage = usage],
  )

