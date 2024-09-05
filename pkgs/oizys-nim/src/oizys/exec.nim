import std/[
  osproc, strformat,
  strutils, streams, logging
]

import ./spin


func addArgs*(cmd: var string, args: openArray[string]) =
  cmd &= " " & args.join(" ")

func addArg*(cmd: var string, arg: string) =
  cmd &= " " & arg

proc runCmd*(cmd: string): int =
  debug fmt"running cmd: {cmd}"
  execCmd cmd

proc runCmdCapt*(cmd: string): tuple[stdout, stderr: string, exitCode: int] =
  let args = cmd.splitWhitespace()
  let p = startProcess(
    args[0],
    args = args[1..^1],
    options = {poUsePath}
  )
  p.inputStream.close()
  let ostrm = outputStream p
  let errstrm = errorStream p
  result.exitCode = -1
  var line: string
  var cnt: int
  while true:
    echo cnt
    if ostrm.readLine(line):
      result.stdout.add line & '\n'
    if errstrm.readLine(line):
      result.stderr.add line & '\n'
    result.exitCode = peekExitCode(p)
    if result.exitCode != -1: break
    inc cnt
  
  # result = (
  #   readAll p.outputStream,
  #   readAll p.errorStream,
  #   waitForExit p
  # )
  close p

proc runCmdCaptWithSpinner*(cmd: string, msg: string = ""): tuple[output, err: string] =
  debug fmt"running command: {cmd}"
  withSpinner(msg):
    let (output, err, code) = runCmdCapt(cmd)
  if code != 0:
    stderr.writeLine("stdout\n" & output)
    stderr.writeLine("stderr\n" & err)
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

proc quitWithCmd*(cmd: string) =
  debug cmd
  quit(execCmd cmd)

