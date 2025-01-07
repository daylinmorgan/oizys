import std/[logging, os, strformat, strutils]
from std/nativesockets import getHostname
import hwylterm, hwylterm/logging
from hwylterm/hwylcli import Count
import ./logging

type
  OizysContext* = object
    flake: string
    hosts: seq[string]
    debug: bool
    ci: bool
    verbose: Count
    resetCache: bool

let currentHost* = getHostName()

proc initContext*(): OizysContext =
  result.hosts = @[currentHost]
  result.flake = "github:daylinmorgan/oizys"
  let localDir = getHomeDir() / "oizys"
  if localDir.dirExists:
    result.flake = localDir
  let envVar = getEnv("OIZYS_DIR")
  if envVar != "":
    result.flake = envVar
  result.ci = getEnv("GITHUB_STEP_SUMMARY") != ""

var oc = initContext()

proc checkPath(s: string): string =
  ## fail if path doesn't exist
  if not s.dirExists: fatalQuit fmt"flake path: {s} does not exist"
  result = s

proc updateContext*(
  host: seq[string],
  flake: string,
  verbose: Count,
  resetCache: bool
) =
  if host.len > 0: oc.hosts = host
  oc.verbose = verbose
  if verbose.val > 1:
    consoleLogger.levelThreshold = lvlAll
  oc.resetCache = resetCache
  if flake != "":
    oc.flake =
      if flake.startsWith("github") or flake.startsWith("git+"): flake
      else: checkPath(flake.normalizedPath().absolutePath())

  debug bb(fmt"""[b]flake[/]: {oc.flake}, [b]hosts[/]: {oc.hosts.join(" ")}""")


proc getVerbosity*(): int     = return oc.verbose.val
proc getHosts*(): seq[string] = return oc.hosts
proc getFlake*(): string      = return oc.flake
proc isResetCache*(): bool    = return oc.resetCache
proc isCi*(): bool            = return oc.ci
