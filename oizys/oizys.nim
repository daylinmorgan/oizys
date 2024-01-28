import std/[logging, os, osproc, tables, times]
from std/nativesockets import getHostname


var logger = newConsoleLogger()
addHandler(logger)
let summaryFile = getEnv("GITHUB_STEP_SUMMARY")

type
  OizysContext = object
    flake, host: string
    cache = "daylin"
    nom: bool = true

proc newCtx(): OizysContext =
  result = OizysContext()
  result.flake = getEnv("FLAKE_PATH", getEnv("HOME") / "oizys")
  result.host = getHostname()

proc systemFlakePath(c: OizysContext): string =
  c.flake & "#nixosConfigurations." & c.host & ".config.system.build.toplevel"

proc execQuit(cmd: string) =
  quit (execCmd cmd)

proc build(c: OizysContext) =
  ## build nixos
  let
    cmd = if c.nom: "nom" else: "nix"
  execQuit cmd & " build " & c.systemFlakePath

proc dry(c: OizysContext) =
  ## poor man's nix flake check
  execQuit "nix build " & c.systemFlakePath & " --dry-run"

proc cache(c: OizysContext) =
  # Simple benchmarking
  let start = cpuTime()
  let code = execCmd """
    cachix watch-exec """ & c.cache & """ \
        -- \
        nix build """ & c.systemFlakePath & """ \
        --print-build-logs \
        --accept-flake-config
    """
  let duration = (cpuTime() - start)
  if code != 0:
    error "faile to build configuration for: ", c.host

  if summaryFile != "":
    writeFile(
      summaryFile,
      "Built host: " & c.host & " in " & $duration & " seconds"
    )
  info "Built host: " & c.host & " in " & $duration & " seconds"


proc nixosRebuild(c: OizysContext, cmd: string) =
  execQuit "sudo nixos-rebuild " & cmd & " " & " --flake " & c.flake

proc boot(c: OizysContext) =
  ## nixos rebuild boot
  nixosRebuild c, "build"

proc switch(c: OizysContext) =
  ## nixos rebuild switch
  nixosRebuild c, "switch"

const usage = """
oizys <cmd> [opts]
  commands:
    dry     poor man's nix flake check
    boot    nixos-rebuild boot
    switch  nixos-rebuild switch
    cache   build and push to cachix
    build   build system flake

  options:
    --help  > show this help
    -h|--host  > hostname (current host)
    -f|--flake > path to flake ($FLAKE_PATH or $HOME/styx)
    -c|--cache > name of cachix binary cache (daylin)
"""

proc runCmd(c: OizysContext, cmd: string) =
  case cmd:
    of "dry": dry c
    of "switch": switch c
    of "boot": boot c
    of "cache": cache c
    of "build": build c
    else:
      error "unknown command: ", cmd
      echo usage
      quit 1


proc parseFlag(c: var OizysContext, key, val: string) = 
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
    echo "please specify a command"
    echo usage; quit 1

  info $c
  runCmd c, cmd
