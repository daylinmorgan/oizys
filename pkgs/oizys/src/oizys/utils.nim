import std/[strformat, strutils, osproc, sugar, httpclient, terminal, wordwrap]
import hwylterm
import ./[nix, exec, logging]


# TODO: refactor runCmdCaptWithSpinner so it works in getBuildHash
proc checkBuild(installable: string): tuple[stdout: string, stderr: string] =
  var
    output, err: string
    code: int
  let cmd = nixCommand("build").addArgs(installable)
  with(Dots2, bbfmt"attempt to build: [b]{installable}"):
    (output, err, code) = runCmdCapt(cmd, capture = {CaptStdout, CaptStderr})
  if code == 0:
    fatalQuit fmt"{cmd} had zero exit"
  result = (output, err)

proc getBuildHash*(installable: string): string =
  let (output, err) = checkBuild(installable)
  for line in err.splitLines():
    if line.strip().startsWith("got: "):
      let s = line.split("got:")
      result = s[1].strip()
  if result == "":
    stderr.write formatStdoutStderr(output, err) & "\n"
    fatalQuit "failed to find update hash from above output"

proc getCaches(): seq[string] =
  ## use nix to get the current cache urls
  debug "determing caches to check"
  let (output, code) = execCmdEx("nix config show")
  if code != 0:
    echo formatSubprocessError(output)
    fatalQuit "error running `nix config show`"

  for line in output.splitLines():
    if line.startsWith("substituters ="):
      let s = line.split("=")[1].strip()
      for u in s.split():
        result.add u

  if result.len == 0:
    echo formatSubprocessError(output)
    fatalQuit "error running `nix config show`"


proc hasNarinfo*(cache: string, path: string): tuple[exists:bool, narinfo:string] =
  debug fmt"checking {cache} for {path}"
  let
    hash = narHash(path)
    url = cache & "/" & hash & ".narinfo"

  var client = newHttpClient()
  try:
    let res = client.get(url)
    result.exists = res.code == Http200
    result.narinfo = res.body.strip()
    # if result and getVerbosity() > 0:
    #     info "narinfo:\n" & indent(res.body.strip(),2)
  finally:
    client.close()

proc prettyDerivation(path: string): BbString =
  let drv = path.toDerivation()
  const maxLen = 40
  result.add drv.name.trunc(maxLen).alignLeft(maxLen)
  result.add " "
  result.add drv.hash.bb("faint")

proc showNarInfo(s: string): BbString =
  let maxWidth = terminalWidth()
  result.add "narinfo:"
  for line in s.splitLines():
    let
      ss = line.split(": ", maxsplit = 1)
      (k, v) = (ss[0], ss[1])
    result.add bbfmt("\n[b]{k}[/]: ")
    if (len(v) - len(k) + 2) > maxWidth:
      result.add "\n  " & wrapWords(v, maxLineWidth = maxWidth - 2, newLine="\n  ")
    else:
      result.add v

proc checkForCache*(installables: seq[string], caches: seq[string]) =
  let caches =
    if caches.len > 0: caches
    else: getCaches()
  let drvs = nixDerivationShow(installables)
  # outputs['outs'] might blow up
  let outs = collect:
    for name, drv in drvs:
      {name: drv.outputs["out"].path}

  for name, path in outs:
    var found = false
    for cache in caches:
      let (exists, narinfo) = hasNarinfo(cache, path)
      if exists:
        found = true
        info prettyDerivation(path)
        info fmt"exists in {cache}"
        debug showNarinfo(narinfo)
        break

    if not found:
      info fmt"failed to find:"
      info prettyDerivation(path)

