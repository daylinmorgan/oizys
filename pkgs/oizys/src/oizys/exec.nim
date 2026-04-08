import std/[logging, os, osproc, posix, selectors, strformat, strutils]
import hwylterm

iterator splitLinesFinal(s: string): tuple[line: string, final: bool] =
  let lines = s.strip().splitLines(keepEol = true)
  for i, line in lines:
    yield (line: line, final: i == lines.high)

proc appendError*(s1: BbString | string, s2: string, count: Natural = 2): BbString =
  result.add s1
  result.add ":\n"
  for (l, final) in s2.splitLinesFinal():
    result.add if final: "╰ ".bb("red") else: "│ ".bb("red")
    result.add l

type Command* = object
  exe*: string
  args*: seq[string]

func new*(T: typedesc[Command], s: string, args: varargs[string]): T =
  T(exe: s, args: @args)

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

proc run*(c: Command): int {.discardable.} =
  debug "running cmd: " & $c
  execCmd toShell(c)

proc runOk*(c: Command): bool =
  c.run() == 0

proc runQuit*(cmd: Command) =
  quit cmd.run()

proc readAvailable(fd: cint): string =
  let oldFlags = fcntl(fd, F_GETFL, 0)
  discard fcntl(fd, F_SETFL, oldFlags or O_NONBLOCK)
  var buffer = newString(4096)
  while true:
    let bytesRead = read(fd, addr buffer[0], buffer.len)
    if bytesRead > 0:
      result.add(buffer[0 ..< bytesRead])
    elif bytesRead == 0:
      break
    else:
      if errno == EAGAIN or errno == EWOULDBLOCK:
        break
      else:
        break
  discard fcntl(fd, F_SETFL, oldFlags)

type StderrMode = enum smCapture, smPassthrough

proc runCaptImpl(
    cmd: Command, stderrMode: StderrMode
): tuple[stdout, stderr: string, exitCode: int] =
  debug fmt"running cmd: {cmd}"
  let p = startProcess(cmd.exe, args = cmd.args, options = {poUsePath})

  let stdoutFd = p.outputHandle.int.cint
  let stderrFd = p.errorHandle.int.cint

  var selector = newSelector[int]()
  selector.registerHandle(p.outputHandle.int.FileHandle, {Event.Read}, 0)
  selector.registerHandle(p.errorHandle.int.FileHandle, {Event.Read}, 1)

  while p.running():
    for ev in selector.select(10):
      let isStdout = ev.fd == stdoutFd.int
      let data = readAvailable(if isStdout: stdoutFd else: stderrFd)
      if data.len > 0:
        if isStdout:
          result.stdout.add data
        else:
          case stderrMode
          of smCapture: result.stderr.add data
          of smPassthrough: stderr.write data

  # drain any remaining data after process exits
  let outRem = readAvailable(stdoutFd)
  if outRem.len > 0:
    result.stdout.add outRem
  let errRem = readAvailable(stderrFd)
  if errRem.len > 0:
    case stderrMode
    of smCapture: result.stderr.add errRem
    of smPassthrough: stderr.write errRem

  selector.close()
  result.exitCode = p.waitForExit()
  p.close()

proc runCapt*(cmd: Command): tuple[stdout, stderr: string, exitCode: int] =
  runCaptImpl(cmd, smCapture)

proc runCaptStdout*(cmd: Command): tuple[stdout: string, exitCode: int] =
  ## like runCapt except stderr is passed through
  let r = runCaptImpl(cmd, smPassthrough)
  (r.stdout, r.exitCode)

proc formatSubprocessError*(s: string): BbString =
  for line in s.strip().splitLines():
    result.add bb("[red]->[/] " & line & "\n")

proc formatStdoutStderr*(stdout: string, stderr: string): BbString =
  template add(stream: string) =
    if stream.strip() != "":
      result.add astToStr(stream).bb("bold").appendError(stream)

  add(stdout)
  add(stderr)

proc runCaptSpin*(
    cmd: Command, msg: BbString | string = bb"", check: bool = true
): tuple[output, err: string] =
  var
    output, err: string
    code: int
  withSpinner(msg):
    (output, err, code) = runCapt(cmd)
  if check and code != 0:
    stderr.write($formatStdoutStderr(output, err) & "\n")
    error fmt"{cmd} had non zero exit"
    quit code
  return (output, err)
