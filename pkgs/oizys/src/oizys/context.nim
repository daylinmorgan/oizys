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
    bootstrap: bool

let currentHost* = getHostName()

proc initContext*(): OizysContext =
  result.hosts = @[currentHost]
  #
  # result.flake = "github:daylinmorgan/oizys"
  # # this logic alongside the `isBootstrap` should happen in updateContext
  # let localDir = getHomeDir() / "oizys"
  # if localDir.dirExists:
  #   result.flake = localDir
  # let envVar = getEnv("OIZYS_DIR")
  # if envVar != "":
  #   result.flake = envVar
  # result.ci = getEnv("GITHUB_STEP_SUMMARY") != ""


var oc = initContext()

proc getVerbosity*(): int     = return oc.verbose.val
proc getHosts*(): seq[string] = return oc.hosts
proc getFlake*(): string      = return oc.flake
proc isResetCache*(): bool    = return oc.resetCache
proc isCi*(): bool            = return oc.ci
proc isLocal*(): bool         = return oc.flake.dirExists
proc isBootstrap*(): bool     = return oc.bootstrap

proc checkPath(s: string): string =
  ## fail if path doesn't exist
  if not s.dirExists: fatalQuit fmt"flake path: {s} does not exist"
  result = s

func isGitFlakeUrl(flake: string): bool =
  for s in ["github","git+"]:
    if flake.startsWith(s):
      return true

proc updateContext*(
  host: seq[string],
  flake: string,
  verbose: Count,
  resetCache: bool,
  bootstrap: bool,
) =
  oc.verbose = verbose
  oc.bootstrap = bootstrap
  if host.len > 0: oc.hosts = host
  oc.resetCache = resetCache
  if flake != "":
    if flake.isGitFlakeUrl():
      oc.flake = flake
    else:
      oc.flake = checkPath(flake.normalizedPath().absolutePath())
  else:
    oc.flake = "github:daylinmorgan/oizys"

  if bootstrap:
    debug bb("[yellow]bootstrap mode![/]")
  else:
    let localDir = getHomeDir() / "oizys"
    if localDir.dirExists:
      oc.flake = localDir
    let envVar = getEnv("OIZYS_DIR")
    if envVar != "":
      oc.flake = envVar

  if (not bootstrap) and (not isLocal()):
    warn "not using local directory for flake"

  oc.ci = getEnv("GITHUB_STEP_SUMMARY") != ""
  debug bb(fmt"""[b]flake[/]: {oc.flake}, [b]hosts[/]: {oc.hosts.join(" ")}""")

