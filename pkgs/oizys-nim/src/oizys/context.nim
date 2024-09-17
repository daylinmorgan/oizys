import std/[logging, os, strformat, strutils]
from std/nativesockets import getHostname
import hwylterm
import ./logging

type
  OizysContext* = object
    flake: string
    hosts: seq[string]
    debug: bool
    ci: bool
    resetCache: bool

proc initContext*(): OizysContext =
  result.hosts = @[getHostname()]
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
  s

proc updateContext*(
  host: seq[string],
  flake: string,
  debug: bool,
  resetCache: bool
) =
  if host.len > 0: oc.hosts = host
  oc.debug = debug
  oc.resetCache = resetCache
  if flake != "":
    oc.flake =
      if flake.startsWith("github") or flake.startsWith("git+"): flake
      else: checkPath(flake.normalizedPath().absolutePath())

  debug bb(fmt"""[b]flake[/]: {oc.flake}, [b]hosts[/]: {oc.hosts.join(" ")}""")

proc getHosts*(): seq[string] = return oc.hosts
proc getFlake*(): string      = return oc.flake
proc isDebug*(): bool         = return oc.debug
proc isResetCache*(): bool    = return oc.resetCache
proc isCi*(): bool            = return oc.ci


