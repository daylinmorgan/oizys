import std/[
  osproc, strformat,
  strutils, streams, logging
]

import hwylterm

func addArgs*(cmd: string, args: varargs[string]): string =
  ## append to string for command
  result = cmd & " " & args.join(" ")

func addArgs*(cmd: var string, args: varargs[string]): string {.discardable.} =
  ## append to string for command
  cmd &= " " & args.join(" ")
  result = cmd

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
      if CaptStdout in capture:
        result.stdout.add outstrm.readAll()
      if CaptStderr in capture:
        result.stderr.add errstrm.readAll()
      break

  close p

proc formatSubprocessError*(s: string): BbString =
  for line in s.splitLines():
    result.add bb("[red]->[/] " & line & "\n")

proc formatStdoutStderr*(stdout: string, stderr: string): BbString =
  template add(stream: string) =
    if stream.strip() != "":
      result.add astToStr(stream).bb("bold") & ":\n"
      result.add formatSubprocessError(stream)
  add(stdout)
  add(stderr)


proc runCmdCaptWithSpinner*(
  cmd: string,
  msg: BbString | string = bb"",
  capture: set[CaptureGrp] = {CaptStdout},
  check: bool = true
): tuple[output, err: string] =
  var
    output, err: string
    code: int
  with(Dots2, msg):
    (output, err, code) = runCmdCapt(cmd, capture)
  if check and code != 0:
    stderr.write($formatStdoutStderr(output,err))
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

proc quitWithCmd*(cmd: string) =
  debug cmd
  quit(execCmd cmd)

