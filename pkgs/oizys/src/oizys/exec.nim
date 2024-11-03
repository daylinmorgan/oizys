import std/[
  osproc, strformat,
  strutils, streams, logging
]

import hwylterm


func addArgs*(cmd: var string, args: openArray[string]) =
  cmd &= " " & args.join(" ")

func addArg*(cmd: var string, arg: string ) =
  cmd &= " " & arg

proc runCmd*(cmd: string): int =
  debug fmt"running cmd: {cmd}"
  execCmd cmd

type
  CaptureGrp* = enum
    CaptStdout
    CaptStderr

# TODO: support both capturing and inheriting the stream?
proc runCmdCapt*(
  cmd: string,
  capture: set[CaptureGrp] = {CaptStdout},
): tuple[stdout, stderr: string, exitCode: int] =
  debug fmt"running cmd: {cmd}"
  let args = cmd.splitWhitespace()
  let p = startProcess(
    args[0],
    args = args[1..^1],
    options = {poUsePath}
  )
  # NOTE: if I didn't use streams could I just read from the file handle instead?
  let
    outstrm = peekableOutputStream p
    errstrm = peekableErrorStream p
  result.exitCode = -1
  var line: string
  while true:
    if CaptStdout in capture:
      if outstrm.readLine(line):
        result.stdout.add line & '\n'
    if CaptStderr in capture:
      if errstrm.readLine(line):
        result.stderr.add line & '\n'
    result.exitCode = peekExitCode(p)
    if result.exitCode != -1: break

  close p

proc runCmdCaptWithSpinner*(
  cmd: string,
  msg: string = "",
  capture: set[CaptureGrp] = {CaptStdout}
): tuple[output, err: string] =
  withSpinner(msg):
    let (output, err, code) = runCmdCapt(cmd, capture)
  if code != 0:
    stderr.writeLine("stdout\n" & output)
    stderr.writeLine("stderr\n" & err)
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

proc quitWithCmd*(cmd: string) =
  debug cmd
  quit(execCmd cmd)

