import std/[logging, os, osproc, tables, times]
from std/nativesockets import getHostname


var logger = newConsoleLogger()
addHandler(logger)

let summaryFilePath = getEnv("GITHUB_STEP_SUMMARY")

proc writeToSummary(msg: string) = 
  let f = open(summaryFilePath, mode = fmAppend)
  write(f,msg)
  close(f)

type
  StyxContext = object
    flake, host: string
    cache = "daylin"
    nom: bool = true

proc newCtx(): StyxContext =
  result = StyxContext()
  result.flake = getEnv("FLAKE_PATH", getEnv("HOME") / "nixcfg")
  result.host = getHostname()

proc systemFlakePath(c: StyxContext): string =
  c.flake & "#nixosConfigurations." & c.host & ".config.system.build.toplevel"

proc execQuit(cmd: string) =
  quit (execCmd cmd)

proc build(c: StyxContext) =
  ## build nixos
  let
    cmd = if c.nom: "nom" else: "nix"
  execQuit cmd & " build " & c.systemFlakePath

proc dry(c: StyxContext) =
  ## poor man's nix flake check
  execQuit "nix build " & c.systemFlakePath & " --dry-run"

proc cache(c: StyxContext) =
  ## build and upload to binary cache
  let start = getTime()
  let code = execCmd """
    cachix watch-exec """ & c.cache & """ \
        -- \
        nix build """ & c.systemFlakePath & """ \
        --print-build-logs \
        --accept-flake-config
    """
  let duration = (getTime() - start)
  if code != 0:
    error "failed to build configuration for: ", c.host

  if summaryFilePath != "":
    writeToSummary(
      "Built host: " & c.host & " in " & $duration & " seconds"
    )
  info "Built host: " & c.host & " in " & $duration & " seconds"

proc touchPr(c: StyxContext) =
  const cmds = ["git branch -D update_flake_lock_action",
   "git fetch origin",
   "git checkout update_flake_lock_action",
   "git commit --amend --no-edit",
   "git push origin update_flake_lock_action --force"]
  for cmd in cmds:
    let code = execCmd cmd
    if code != 0:
      error "command: ",cmd,"exited with code: ",$code

proc nixosRebuild(c: StyxContext, cmd: string) =
  execQuit "sudo nixos-rebuild " & cmd & " " & " --flake " & c.flake

proc boot(c: StyxContext) =
  ## nixos rebuild boot
  nixosRebuild c, "build"

proc switch(c: StyxContext) =
  ## nixos rebuild switch
  nixosRebuild c, "switch"

proc runCmd(c: StyxContext, cmd: string) =
  case cmd:
    of "dry": dry c
    of "switch": switch c
    of "boot": boot c
    of "cache": cache c
    of "build": build c
    of "touch-pr": touchPr c
    else:
      error "unknown command: ", cmd
      quit 1


const usage = """
styx <cmd> [opts]
  commands:
    dry      poor man's nix flake check
    boot     nixos-rebuild boot
    switch   nixos-rebuild switch
    cache    build and push to cachix
    build    build system flake
    touch-pr trigger Github Action Ci

  options:
    --help     > show this help
    -h|--host  > hostname (current host)
    -f|--flake > path to flake ($FLAKE_PATH or $HOME/styx)
    -c|--cache > name of cachix binary cache (daylin)
"""

proc parseFlag(c: var StyxContext, key, val: string) = 
  case key:
    of "help":
      echo usage; quit 0
    of "h","host":
      c.host = val
    of "f","flake":
      c.flake = val
    of "no-nom":
      c.nom = false

when isMainModule:
  import std/parseopt
  var
    c = newCtx()
    cmd: string
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      cmd = key
    of cmdLongOption, cmdShortOption:
      parseFlag c, key, val
    of cmdEnd:
      discard
  if cmd == "":
    echo "please specify a command, see below"
    echo usage; quit 1
  info $c
  runCmd c, cmd
