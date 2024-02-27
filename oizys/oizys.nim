import std/[os, osproc, parseopt, times, strutils, terminal]
from std/nativesockets import getHostname

let summaryFile = getEnv("GITHUB_STEP_SUMMARY")

proc info(args: varargs[string, `$`]) =
  stdout.styledWriteLine(
    fgCyan, "oizys", resetStyle, "|",
    styleDim, "INFO", resetStyle, "| ",
    args.join("")
  )

proc error(args: varargs[string, `$`]) =
  stdout.styledWriteLine(
    fgCyan, "oizys", resetStyle, "|",
    fgRed, "ERROR", resetStyle, "| ",
    args.join("")
  )

type
  OizysContext = object
    flake, host: string
    extraArgs: seq[string]
    cache = "daylin"
    pinix: bool = true

proc execQuit(c: OizysContext, args: varargs[string]) =
  let cmd = (@args & c.extraArgs).join(" ")
  info "exec: ", cmd
  quit (execCmd cmd)

proc newCtx(): OizysContext =
  result = OizysContext()
  result.flake = getEnv("FLAKE_PATH", getEnv("HOME") / "oizys")
  result.host = getHostname()

proc check(c: OizysContext) =
  if not dirExists c.flake:
    error c.flake, " does not exist"
    error "please use -f/--flake or $FLAKE_PATH"
    quit 1
  info "flake: ", c.flake
  info "host: ", c.host

proc cmd(c: OizysContext): string {.inline.} =
  if c.pinix: "pix" else: "nix"

proc systemFlakePath(c: OizysContext): string =
  c.flake & "#nixosConfigurations." & c.host & ".config.system.build.toplevel"

proc build(c: OizysContext) =
  ## build nixos
  execQuit c, c.cmd, "build", c.systemFlakePath

proc dry(c: OizysContext) =
  ## poor man's nix flake check
  execQuit c, c.cmd, "build", c.systemFlakePath, "--dry-run"

proc cache(c: OizysContext) =
  let start = now()
  let code = execCmd """
    cachix watch-exec """ & c.cache & """ \
        -- \
        nix build """ & c.systemFlakePath & """ \
        --print-build-logs \
        --accept-flake-config
    """
  let duration = (now() - start)
  if code != 0:
    error "faile to build configuration for: ", c.host

  if summaryFile != "":
    writeFile(
      summaryFile,
      "Built host: " & c.host & " in " & $duration & " seconds"
    )
  info "Built host: " & c.host & " in " & $duration & " seconds"


proc nixosRebuild(c: OizysContext, subcmd: string) =
  let cmd = if c.pinix: "pixos-rebuild" else: "nixos-rebuild"
  execQuit c, "sudo", cmd, subcmd, "--flake", c.flake

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
  -h|--help      show this help
     --host      hostname (current host)
  -f|--flake     path to flake ($FLAKE_PATH or $HOME/oizys)
  -c|--cache     name of cachix binary cache (daylin)
     --no-pinix  don't use pinix
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


proc parseFlag(c: var OizysContext, kind: CmdLineKind, key, val: string) =
  case key:
    of "h", "help":
      echo usage; quit 0
    of "host":
      c.host = val
    of "f", "flake":
      c.flake = val
    of "no-pinix":
      c.pinix = false
    else:
      c.extraArgs.add (if kind == cmdLongOption: "--" else: "-") & key
      c.extraArgs.add val

when isMainModule:
  var
    c = newCtx()
    subcmd: string
  var p = initOptParser(
    longNoVal = @["no-pinix", "help", ""], shortNoVal = {'h'}
  )
  for kind, key, val in p.getopt():
    case kind
    of cmdArgument:
      echo key
      subcmd = key
    of cmdLongOption, cmdShortOption:
      if key == "":
        break
      parseFlag c, kind, key, val
    of cmdEnd:
      discard
  if subcmd == "":
    echo "please specify a command"
    echo usage; quit 1
  c.extraArgs = p.remainingArgs
  check c
  runCmd c, subcmd
