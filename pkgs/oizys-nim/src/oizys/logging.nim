import std/[logging,strutils]
export logging

import bbansi

var
  handlers {.threadvar.}: seq[Logger]

#[
Level* = enum ## \
    lvlAll,     ## All levels active
    lvlDebug,   ## Debug level and above are active
    lvlInfo,    ## Info level and above are active
    lvlNotice,  ## Notice level and above are active
    lvlWarn,    ## Warn level and above are active
    lvlError,   ## Error level and above are active
    lvlFatal,   ## Fatal level and above are active
    lvlNone     ## No levels active; nothing is logged
]#

type
  FancyConsoleLogger* = ref object of Logger
    ## A logger that writes log messages to the console.
    ##
    ## Create a new ``FancyConsoleLogger`` with the `newFancyConsoleLogger proc
    ## <#newConsoleLogger>`_.
    ##
    useStderr*: bool ## If true, writes to stderr; otherwise, writes to stdout
    flushThreshold*: Level ## Only messages that are at or above this
                           ## threshold will be flushed immediately
    fmtPrefix: string
    fmtSep: string
    fmtStrs: array[Level, string]


const defaultFlushThreshold = lvlAll

proc genFmtStr(
  fmtPrefix, fmtSep, fmtSuffix, levelBb: string,
  level: Level
): string =
  var parts: seq[string]
  if fmtPrefix != "": parts.add fmtPrefix
  parts.add $LevelNames[level].bb(levelBb)
  return parts.join(fmtSep) & fmtSuffix


proc newFancyConsoleLogger*(
  levelThreshold = lvlAll,
  fmtPrefix= "",
  fmtSep = "|",
  fmtSuffix ="| ",
  useStderr = false,
  flushThreshold = defaultFlushThreshold,
  debugBb: string = "faint",
  infoBb: string = "bold",
  noticeBb: string = "bold",
  warnBb: string = "bold yellow",
  errorBb: string = "bold red",
  fatalBb: string = "bold red"
): FancyConsoleLogger =
  ## Creates a new `FancyConsoleLogger<#ConsoleLogger>`_.
  new result
  let fmtStrs: array[Level, string] = [
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, "", lvlAll),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, debugBb, lvlDebug),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, infobb, lvlInfo),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, noticeBb, lvlNotice),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, warnBb, lvlWarn),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, errorBb, lvlError),
      genFmtStr(fmtPrefix,fmtSep, fmtSuffix, fatalBb, lvlFatal),
      genFmtStr(fmtPrefix, fmtSep, fmtSuffix, "", lvlNone)
  ]
  result.fmtPrefix = fmtPrefix
  result.fmtSep = fmtSep
  result.levelThreshold = levelThreshold
  result.flushThreshold = flushThreshold
  result.useStderr = useStderr
  result.fmtStrs = fmtStrs


method log*(logger: FancyConsoleLogger, level: Level, args: varargs[string, `$`]) {.gcsafe.} =
  ## Logs to the console with the given `FancyConsoleLogger<#ConsoleLogger>`_ only.
  ##
  ## This method ignores the list of registered handlers.
  ##
  ## Whether the message is logged depends on both the ConsoleLogger's
  ## ``levelThreshold`` field and the global log filter set using the
  ## `setLogFilter proc<#setLogFilter,Level>`_.
  ##
  ## **Note:** Only error and fatal messages will cause the output buffer
  ## to be flushed immediately by default. Set ``flushThreshold`` when creating
  ## the logger to change this.

  if level >= logger.levelThreshold:
    let ln = substituteLog(logger.fmtStrs[level], level, args)
    when defined(js): {.fatal: "handler does note support JS".}
    try:
      let handle =
        if logger.useStderr: stderr 
        else: stdout
      writeLine(handle, ln)
      if level >= logger.flushThreshold: flushFile(handle)
    except IOError:
      discard

proc addHandlers*(handler: Logger) =
  handlers.add(handler)
