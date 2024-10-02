## nix begat oizys
import std/[os, tables, sequtils, strformat, strutils]
import hwylterm, hwylterm/[cligen, logging]
import oizys/[context, github, nix, overlay, logging]


proc confirm(q: string): bool =
  stderr.write $(q & bb"[yellow] (Y/n) ")
  while true:
    let ans = readLine(stdin)
    case ans.strip().toLowerAscii():
    of "y","yes": return true
    of "n","no": return false
    else:
      stderr.write($bb("[red]Please answer Yes/no\nexpected one of [b]Y,yes,N,no "))
  stderr.write "\n"

overlay:
  proc pre(
    flake: string = "",
    host: seq[string] = @[],
    debug: bool = false,
    resetCache: bool = false,
    rest: seq[string],
  ) =
    setupLoggers(debug)
    updateContext(host, flake, debug, resetCache)

  proc dry(minimal: bool = false) =
    ## dry run build
    nixBuildHostDry(minimal, rest)

  proc output(yes: bool = false) =
    ## nixos config attr
    echo nixosConfigAttrs().join(" ")

  proc update(
    yes: bool = false,
    preview: bool = false
  ) =
    ## update and run nixos-rebuild
    let hosts = getHosts()
    if hosts.len > 1: fatalQuit "operation only supports one host"
    let run = getLastUpdateRun()
    echo fmt"run created at: {run.created_at}"
    echo "nvd diff:\n", getUpdateSummary(run.id, hosts[0])
    if preview: quit 0
    if yes or confirm("Proceed with system update?"):
      updateRepo()
      nixosRebuild("switch")

  proc build(minimal: bool = false) =
    ## nix build
    nixBuild(minimal, rest)

  proc cache(minimal: bool = false, name: string = "daylin") =
    ## build and push to cachix
    nixBuildWithCache(minimal, name, rest)

  proc osCmd() =
    ## nixos-rebuild
    if len(rest) == 0: fatalQuit "please provide subcmd"
    let subcmd = rest[0]
    if subcmd notin nixosSubcmds:
      fatalQuit(
        &"unknown nixos-rebuild subcmd: {subcmd}\nexpected one of: \n" &
        nixosSubcmds.mapIt("  " & it).join("\n")
      )
    nixosRebuild(subcmd, rest[1..^1])

  proc ci(`ref`: string = "main") =
    ## trigger GHA update flow
    if rest.len == 0: fatalQuit "expected workflow file name"
    createDispatch(rest[0], `ref`)

proc checkExes() =
  if findExe("nix") == "":
    fatalQuit "oizys requires nix"

# func `//`[A, B](pairs: openArray[(A, B)]): Table[A, B] =
#   pairs.toTable()
# func `//`[A, B](t1: var Table[A,B], t2: Table[A,B]) =
#   for k, v in t2.pairs(): t1[k] = v
# func `//`[A, B](t1: Table[A, B], t2: Table[A, B]): Table[A, B] =
#   result // t1; result // t2
# func `//`[A, B](pairs: openArray[(A,B)], t2: Table[A,B]): Table[A,B] =
#   // pairs // t2
#
#

when isMainModule:
  import cligen
  checkExes()
  hwylCli(clCfg)

  const
    sharedHelp = //{
      "flake"      : "path/to/flake",
      "host"       : "host(s) to build",
      "debug"      : "enable debug mode",
      "resetCache" : "set cache timeout to 0"
    }
    updateHelp = //{
      "yes"        : "skip all confirmation prompts"
    } // sharedHelp
    ciHelp     = //{
      "ref"        : "git ref/branch/tag to trigger workflow on"
    }
    cacheHelp = //{
      "name"       : "name of cachix binary cache"
    } // sharedHelp
  let
    # clUse must be set here using clCfg doesn't seem to work with dispatchMutli ...
    # clUse* = $bb("$command $args\n${doc}[bold]Options[/]:\n$options")
    osUsage = $bb("$command [[subcmd] $args\n$doc[bold]Options[/]:\n$options")

  dispatchMulti(
    [build,  help = sharedHelp, usage = clCfg.use ],
    [cache,  help = cacheHelp , usage = clCfg.use ],
    [ci,     help = ciHelp    , usage = clCfg.use ],
    [dry,    help = sharedHelp, usage = clCfg.use ],
    [osCmd,  help = sharedHelp, usage = osUsage, cmdName = "os"],
    [output, help = sharedHelp, usage = clCfg.use],
    [update, help = updateHelp, usage = clCfg.use],
  )

