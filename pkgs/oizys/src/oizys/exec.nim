import std/[osproc, strformat, os, strutils, streams, logging, selectors, posix]

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

#[
  hasData, readAvailable, runCapt
  partially generated with the help of claude ¯\_(ツ)_/¯
]#

proc hasData(handle: FileHandle, timeoutMs: int = 10): bool =
  var selector = newSelector[int]()
  selector.registerHandle(handle.int.FileHandle, {Event.Read}, 0)
  result = selector.select(timeoutMs).len > 0
  selector.close()

proc readAvailable(fd: cint): string =
  # Get current flags
  let oldFlags = fcntl(fd, F_GETFL, 0)

  # Set non-blocking
  discard fcntl(fd, F_SETFL, oldFlags or O_NONBLOCK)

  var
    buffer = newString(4096)
    bytesRead: int

  # Read in chunks until no more data
  while true:
    bytesRead = read(fd, addr buffer[0], buffer.len)

    if bytesRead > 0:
      result.add(buffer[0 ..< bytesRead])
    else:
      break # No more data or error

  # Restore flags
  discard fcntl(fd, F_SETFL, oldFlags)

  return result

proc runCapt*(cmd: Command): tuple[stdout, stderr: string, exitCode: int] =
  debug fmt"running cmd: {cmd}"
  let p = startProcess(cmd.exe, args = cmd.args, options = {poUsePath})

  var stdoutData, stderrData: string

  # Get raw file descriptors
  let stdoutFd = p.outputHandle.int.cint
  let stderrFd = p.errorHandle.int.cint

  # Main reading loop
  while p.running():
    var dataRead = false

    # Check if stdout has data
    if p.outputHandle.hasData():
      let data = readAvailable(stdoutFd)
      if data.len > 0:
        stdoutData.add(data)
        dataRead = true

    # Check if stderr has data
    if p.errorHandle.hasData():
      let data = readAvailable(stderrFd)
      if data.len > 0:
        stderrData.add(data)
        dataRead = true

    # Avoid tight loops
    if not dataRead:
      sleep(5)

  # Process has ended, read any remaining data
  if p.outputHandle.hasData():
    let data = readAvailable(stdoutFd)
    if data.len > 0:
      stdoutData.add(data)

  if p.errorHandle.hasData():
    let data = readAvailable(stderrFd)
    if data.len > 0:
      stderrData.add(data)

  result.exitCode = p.peekExitCode
  result.stdout = stdoutData
  result.stderr = stderrData
  close(p)

proc runCaptStdout*(cmd: Command): tuple[stdout: string, exitCode: int] =
  ## like runCapt except stderr is passed through
  debug fmt"running cmd: {cmd}"
  let p = startProcess(cmd.exe, args = cmd.args, options = {poUsePath})

  var stdoutData: string

  # Get raw file descriptors
  let stdoutFd = p.outputHandle.int.cint
  let stderrFd = p.errorHandle.int.cint

  # Main reading loop
  while p.running():
    var dataRead = false

    # Check if stdout has data
    if p.outputHandle.hasData():
      let data = readAvailable(stdoutFd)
      if data.len > 0:
        dataRead = true
        stdoutData.add(data)

    # Check if stderr has data
    if p.errorHandle.hasData():
      let data = readAvailable(stderrFd)
      if data.len > 0:
        dataRead = true
        stderr.write(data)

    # Avoid tight loops
    if not dataRead:
      sleep(5)

  # Process has ended, read any remaining data
  if p.outputHandle.hasData():
    let data = readAvailable(stdoutFd)
    if data.len > 0:
      stdoutData.add(data)

  if p.errorHandle.hasData():
    let data = readAvailable(stderrFd)
    if data.len > 0:
      stderr.write(data)

  result.stdout = stdoutData
  result.exitCode = p.peekExitCode
  close(p)

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
