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
): tuple[stdout, stderr: string, exitCode: int] =
  debug fmt"running cmd: {cmd}"
  let p = startProcess(
    cmd.exe,
    args = cmd.args,
    options = {poUsePath}
  )

  let
    outstrm = peekableOutputStream p
    errstrm = peekableErrorStream p
  result.exitCode = -1

  var stdoutLines, stderrLines: seq[string]
  var line: string
  while outstrm.readLine(line):
    stdoutLines.add line
  result.stdout = stdoutLines.join("\n")

  while errstrm.readLine(line):
    stderrLines.add line
  result.stderr = stderrLines.join("\n")

  close outstrm
  close errstrm

  result.exitCode = p.waitForExit()
  close p


proc formatSubprocessError*(s: string): BbString =
  for line in s.strip().splitLines():
    result.add bb("[red]->[/] " & line & "\n")

proc formatStdoutStderr*(stdout: string, stderr: string): BbString =
  template add(stream: string) =
    if stream.strip() != "":
      result.add astToStr(stream).bb("bold") & ":\n"
      result.add formatSubprocessError(stream)
  add(stdout)
  add(stderr)


proc runCaptSpin*(
  cmd: Command,
  msg: BbString | string = bb"",
  check: bool = true
): tuple[output, err: string] =
  var
    output, err: string
    code: int
  with(Dots2, msg):
    (output, err, code) = runCapt(cmd)
  if check and code != 0:
    stderr.write($formatStdoutStderr(output,err))
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)

