import std/[
  osproc, strformat, os,
  strutils, streams, logging
]

import hwylterm

type
  Command* = object
    exe*: string
    args*: seq[string]

func newCommand*(s: string, args: varargs[string]): Command =
  result.exe = s
  result.args = @args

func `$`*(c: Command): string =
  c.exe & " " & c.args.join(" ")

func toShell(c: Command): string =
  quoteShellCommand(@[c.exe] & c.args)

func addArgs*(c: var Command, args: varargs[string]) =
  ## append args to command
  c.args &= args

func withArgs*(c: Command, args: varargs[string]): Command {.discardable.} =
  result.exe = c.exe
  result.args = (c.args & @args)


proc run*(c: Command): int  {.discardable.}=
  debug "running cmd: " & $c
  execCmd toShell(c)


proc runQuit*(cmd: Command) =
  quit cmd.run()

# Should all subcommands just go through a version of runCmdCapt?
type
  CaptureGrp* = enum
    CaptStdout
    CaptStderr

# TODO: support both capturing and inheriting the stream?
# TODO: replace cmd with Command
proc runCapt*(
  cmd: Command,
  capture: set[CaptureGrp] = {CaptStdout},
): tuple[stdout, stderr: string, exitCode: int] =
  debug fmt"running cmd: {cmd}"
  let p = startProcess(
    cmd.exe,
    args = cmd.args,
    options = {poUsePath}
  )
  # NOTE: if I didn't use streams could I just read from the file handle instead?
  let
    outstrm = peekableOutputStream p
    errstrm = peekableErrorStream p
  result.exitCode = -1
  var line: string
  # BUG: the readLine's hang if there is no data. would peek also hang?
  while true:
    if CaptStdout in capture and not outstrm.atEnd():
      if outstrm.readLine(line):
        result.stdout.add line & '\n'
    if CaptStderr in capture and not errstrm.atEnd():
      if errstrm.readLine(line):
        result.stderr.add line & '\n'
    result.exitCode = peekExitCode(p)
    if result.exitCode != -1:
      if CaptStdout in capture and not isNil(outstrm):
        result.stdout.add outstrm.readAll()
      if CaptStderr in capture and not isNil(errstrm):
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


proc runCaptWithSpinner*(
  cmd: Command,
  msg: BbString | string = bb"",
  capture: set[CaptureGrp] = {CaptStdout},
  check: bool = true
): tuple[output, err: string] =
  var
    output, err: string
    code: int
  with(Dots2, msg):
    (output, err, code) = runCapt(cmd, capture)
  if check and code != 0:
    stderr.write($formatStdoutStderr(output,err))
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

