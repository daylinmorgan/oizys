import std/[
  osproc, strformat,
  strutils, streams, logging
]

import hwylterm
import hwylterm/spin/spinners # todo: remove after hwylterm update


func addArgs*(cmd: var string, args: varargs[string]) =
  cmd &= " " & args.join(" ")

# deprecate in favor of above?
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
    if result.exitCode != -1:
      result.stdout.add outstrm.readAll()
      result.stderr.add errstrm.readAll()
      break

  close p

proc formatStdoutStderr(stdout: string, stderr: string): BbString =
  template add(stream: string) =
    if stream.strip() != "":
      result.add astToStr(stream).bb("bold") & ":\n"
      for line in stream.splitlines():
        result.add bb("[red]->[/] " & line & "\n")
  add(stdout)
  add(stderr)

proc runCmdCaptWithSpinner*(
  cmd: string,
  msg: string = "",
  capture: set[CaptureGrp] = {CaptStdout}
): tuple[output, err: string] =
  var
    output, err: string
    code: int
  with(Dots2, msg):
    (output, err, code) = runCmdCapt(cmd, capture)
  if code != 0:
    stderr.write($formatStdoutStderr(output,err))
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

proc quitWithCmd*(cmd: string) =
  debug cmd
  quit(execCmd cmd)

