import std/[os, locks, sequtils, terminal]

# https://github.com/molnarmark/colorize
proc reset(): string = "\e[0m"

# foreground colors
proc fgRed*(s: string): string = "\e[31m" & s & reset()
proc fgBlack*(s: string): string = "\e[30m" & s & reset()
proc fgGreen*(s: string): string = "\e[32m" & s & reset()
proc fgYellow*(s: string): string = "\e[33m" & s & reset()
proc fgBlue*(s: string): string = "\e[34m" & s & reset()
proc fgMagenta*(s: string): string = "\e[35m" & s & reset()
proc fgCyan*(s: string): string = "\e[36m" & s & reset()
proc fgLightGray*(s: string): string = "\e[37m" & s & reset()
proc fgDarkGray*(s: string): string = "\e[90m" & s & reset()
proc fgLightRed*(s: string): string = "\e[91m" & s & reset()
proc fgLightGreen*(s: string): string = "\e[92m" & s & reset()
proc fgLightYellow*(s: string): string = "\e[93m" & s & reset()
proc fgLightBlue*(s: string): string = "\e[94m" & s & reset()
proc fgLightMagenta*(s: string): string = "\e[95m" & s & reset()
proc fgLightCyan*(s: string): string = "\e[96m" & s & reset()
proc fgWhite*(s: string): string = "\e[97m" & s & reset()

# background colors
proc bgBlack*(s: string): string = "\e[40m" & s & reset()
proc bgRed*(s: string): string = "\e[41m" & s & reset()
proc bgGreen*(s: string): string = "\e[42m" & s & reset()
proc bgYellow*(s: string): string = "\e[43m" & s & reset()
proc bgBlue*(s: string): string = "\e[44m" & s & reset()
proc bgMagenta*(s: string): string = "\e[45m" & s & reset()
proc bgCyan*(s: string): string = "\e[46m" & s & reset()
proc bgLightGray*(s: string): string = "\e[47m" & s & reset()
proc bgDarkGray*(s: string): string = "\e[100m" & s & reset()
proc bgLightRed*(s: string): string = "\e[101m" & s & reset()
proc bgLightGreen*(s: string): string = "\e[102m" & s & reset()
proc bgLightYellow*(s: string): string = "\e[103m" & s & reset()
proc bgLightBlue*(s: string): string = "\e[104m" & s & reset()
proc bgLightMagenta*(s: string): string = "\e[105m" & s & reset()
proc bgLightCyan*(s: string): string = "\e[106m" & s & reset()
proc bgWhite*(s: string): string = "\e[107m" & s & reset()

# formatting functions
proc bold*(s: string): string = "\e[1m" & s & reset()
proc underline*(s: string): string = "\e[4m" & s & reset()
proc hidden*(s: string): string = "\e[8m" & s & reset()
proc invert*(s: string): string = "\e[7m" & s & reset()

type
  SpinnerKind* = enum
    Dots
  Spinner* = object
    interval*: int
    frames*: seq[string]

proc makeSpinner*(interval: int, frames: seq[string]): Spinner =
  Spinner(interval: interval, frames: frames)

const Spinners*: array[SpinnerKind, Spinner] = [
  # Dots
  Spinner(interval: 80, frames: @["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]),
]


type
  Spinny = ref object
    t: Thread[Spinny]
    lock: Lock
    text: string
    running: bool
    frames: seq[string]
    frame: string
    interval: int
    customSymbol: bool

  EventKind = enum
    Stop, StopSuccess, StopError,
    SymbolChange, TextChange,

  SpinnyEvent = object
    kind: EventKind
    payload: string

var spinnyChannel: Channel[SpinnyEvent]

proc newSpinny*(text: string, s: Spinner): Spinny =
  Spinny(
    text: text,
    running: true,
    frames: s.frames,
    customSymbol: false,
    interval: s.interval
  )

proc newSpinny*(text: string, spinType: SpinnerKind): Spinny =
  newSpinny(text, Spinners[spinType])

proc setSymbolColor*(spinny: Spinny, color: proc(x: string): string) =
  spinny.frames = mapIt(spinny.frames, color(it))

proc setSymbol*(spinny: Spinny, symbol: string) =
  spinnyChannel.send(SpinnyEvent(kind: SymbolChange, payload: symbol))

proc setText*(spinny: Spinny, text: string) =
  spinnyChannel.send(SpinnyEvent(kind: TextChange, payload: text))

proc handleEvent(spinny: Spinny, eventData: SpinnyEvent): bool =
  result = true
  case eventData.kind
  of Stop:
    result = false
  of SymbolChange:
    spinny.customSymbol = true
    spinny.frame = eventData.payload
  of TextChange:
    spinny.text = eventData.payload
  of StopSuccess:
    spinny.customSymbol = true
    spinny.frame = "✔".bold.fgGreen
    spinny.text = eventData.payload.bold.fgGreen
  of StopError:
    spinny.customSymbol = true
    spinny.frame = "✖".bold.fgRed
    spinny.text = eventData.payload.bold.fgRed

proc spinnyLoop(spinny: Spinny) {.thread.} =
  var frameCounter = 0

  while spinny.running:
    let data = spinnyChannel.tryRecv()
    if data.dataAvailable:
      # If we received a Stop event
      if not spinny.handleEvent(data.msg):
        spinnyChannel.close()
        # This is required so we can reopen the same channel more than once
        # See https://github.com/nim-lang/Nim/issues/6369
        spinnyChannel = default(typeof(spinnyChannel))
        # TODO: Do we need spinny.running at all?
        spinny.running = false
        break

    stdout.flushFile()
    if not spinny.customSymbol:
      spinny.frame = spinny.frames[frameCounter]

    withLock spinny.lock:
      eraseLine()
      stdout.write(spinny.frame & " " & spinny.text)
      stdout.flushFile()

    sleep(spinny.interval)

    if frameCounter >= spinny.frames.len - 1:
      frameCounter = 0
    else:
      frameCounter += 1

proc start*(spinny: Spinny) =
  initLock(spinny.lock)
  spinnyChannel.open()
  createThread(spinny.t, spinnyLoop, spinny)

proc stop(spinny: Spinny, kind: EventKind, payload = "") =
  spinnyChannel.send(SpinnyEvent(kind: kind, payload: payload))
  spinnyChannel.send(SpinnyEvent(kind: Stop))
  joinThread(spinny.t)
  eraseLine stdout
  flushFile stdout


proc stop*(spinny: Spinny) =
  spinny.stop(Stop)

proc success*(spinny: Spinny, msg: string) =
  spinny.stop(StopSuccess, msg)

proc error*(spinny: Spinny, msg: string) =
  spinny.stop(StopError, msg)

template withSpinner*(msg: string = "", body: untyped): untyped =
  var spinner {.inject.} = newSpinny(msg, Dots)
  spinner.setSymbolColor(fgBlue)
  if isatty(stdout): # don't spin if it's not a tty
    start spinner

  body

  if isatty(stdout):
    stop spinner

template withSpinner*(body: untyped): untyped =
  withSpinner("", body)


