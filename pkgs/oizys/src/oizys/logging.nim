## nix begat oizys
import std/[logging, os]
import hwylterm, hwylterm/logging
export logging


proc getDataDir(): string =
  ## Returns the data directory of the current user for applications.
  # follows std/os.getCacheDir
  # which in turn follows https://crates.io/crates/platform-dirs
  result =
    when defined(windows):
      getEnv("LOCALAPPDATA")
    elif defined(osx):
      getEnv("XDG_DATA_HOME", getEnv("HOME") / "Library/Application Support")
    else:
      getEnv("XDG_DATA_HOME", getEnv("HOME") / ".local/share")

  result.normalizePathEnd(false)

proc getOizysLogPath(): string =
  let dataDir = getDataDir()
  createDir(dataDir / "oizys")
  result = dataDir / "oizys" / "oizys.log"

setLogFilter(lvlAll)

var consoleLogger* = 
  newHwylConsoleLogger(
      fmtPrefix = $bb"[b magenta]oizys",
      fmtSuffix = " ",
      levelThreshold = lvlInfo
  )

proc setupLoggers*() =
  addHandler(
    consoleLogger
  )
  addHandler(
    newRollingFileLogger(
      getOizysLogPath(),
      mode = fmAppend,
      fmtStr = "$datetime | $levelid:"
    )
  )
