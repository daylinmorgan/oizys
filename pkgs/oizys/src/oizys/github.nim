import std/[httpclient,logging, os, strformat, strutils, json, tables, tempfiles, times, strtabs]
import jsony, hwylterm, hwylterm/logging, zippy/ziparchives, resultz
import ./[exec, context]


template withTmpDir(body: untyped): untyped =
  let tmpDir {.inject.} = createTempDir("oizys","")
  body
  removeDir tmpDir

type
  GhArtifact = object
    id: int
    name: string
    url: string
    archive_download_url*: string

  GhWorkflowRun = object
    id*: int
    node_id: string
    run_number: int
    event: string
    status: string
    conclusion: string
    html_url: string
    workflow_id: int
    created_at*: string # use datetime?
    updated_at: string # use datetime?

  ListGhArtifactResponse = object
    total_count: int
    artifacts: seq[GhArtifact]

  ListGhWorkflowResponse = object
    total_count: int
    workflow_runs: seq[GhWorkflowRun]

var ghToken = getEnv "GITHUB_TOKEN"

proc checkToken() {.inline.} =
  if ghToken == "": fatalQuit "GITHUB_TOKEN not set"

proc ghClient(
  maxRedirects = 5
): HttpClient =
  checkToken()
  result = newHttpClient(maxRedirects = maxRedirects)
  result.headers = newHttpHeaders({
    "Accept"              : "application/vnd.github+json",
    "Authorization"       : fmt"Bearer {ghToken}",
    "X-GitHub-Api-Version": "2022-11-28",
  })


proc getGhApi(url: string): Response =
  let client = ghClient()
  try:
    result = client.get(url)
  except:
    error getCurrentExceptionMsg()
    error fmt"github api request failed: {url}"
    if result != nil:
      error fmt"response: {result.body}"
    quit QuitFailure
  finally:
    close client

proc postGhApi(url: string, body: JsonNode) =
  checkToken()
  let client = newHttpClient()
  client.headers = newHttpHeaders({
    "Accept"              : "application/vnd.github+json",
    "Authorization"       : fmt"Bearer {ghToken}",
    "X-GitHub-Api-Version": "2022-11-28",
  })
  var response: Response
  try:
    response = client.post(url, body = $body)
    info fmt"Status: {response.code}"
  except:
    errorQuit "failed to get response code"
  finally:
    close client
  if response.code != Http204:
    errorQuit "failed to post github api request"


proc getInProgressRun(
  workflow: string,
  timeout: int = 10000
): Opt[GhWorkflowRun] =
  ## wait up to 10 seconds to try to fetch ongoing run url
  let
    start = now()
    timeoutDuration = initDuration(milliseconds = timeout)

  withSpinner(fmt"waiting for {workflow} workflow to start"):
    while (now() - start) < timeoutDuration:
      let response = getGhApi(fmt"https://api.github.com/repos/daylinmorgan/oizys/actions/workflows/{workflow}/runs")
      let runs = fromJson(response.body,  ListGhWorkflowResponse).workflow_runs
      if runs[0].status in ["in_progress", "queued"]:
        return ok runs[0]
      sleep 500

  warn "timeout reached waiting for workflow to start"

proc `%`*(table: StringTableRef): JsonNode =
  ## Generic constructor for JSON data. Creates a new `JObject JsonNode`.
  result = newJObject()
  for k, v in table: result[k] = %v

proc createDispatch*(workflowFileName: string, `ref`: string, inputs: StringTableRef) =
  ## https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
  let workflow =
    if workflowFileName.endsWith(".yml") or workflowFileName.endsWith(".yaml"): workflowFileName
    else: workflowFileName & ".yml"
  let body = %*{"ref": `ref`, "inputs": inputs}
  info fmt"creating dispatch event for {workflow}"
  debug "with body: " & $body
  postGhApi(
   fmt"https://api.github.com/repos/daylinmorgan/oizys/actions/workflows/{workflow}/dispatches",
   body
  )
  case getInProgressRun(workflow)
  of Some(run):
    info "view workflow run at: " & run.html_url
  of None:
    warn "couldn't determine workflow url"

proc listUpdateRuns(): seq[GhWorkflowRun] =
  ## get update.yml runs
  ## endpoint https://api.github.com/repos/OWNER/REPO/actions/workflows/WORKFLOW_ID/runs
  debug "listing update workflows"
  let response = getGhApi("https://api.github.com/repos/daylinmorgan/oizys/actions/workflows/update.yml/runs")
  fromJson(response.body,  ListGhWorkflowResponse).workflow_runs

proc getLastUpdateRun*():  GhWorkflowRun =
  let runs = listUpdateRuns()
  let run = runs[0]
  if run.conclusion == "failure":
    fatalQuit bb(fmt("Most recent run was not successful\n[b]runID[/]: {run.id}\n[b]conclusion[/]: {run.conclusion}"))
  if run.status in ["in_progress", "queued"]:
    fatalQuit bb(fmt("Most recent run is not finished\nview workflow run at: {run.html_url}"))
  result = run


proc getArtifacts(runId: int): seq[GhArtifact] =
  ## get workflow artifacts
  ## https://api.github.com/repos/OWNER/REPO/actions/runs/RUN_ID/artifacts
  let response = getGhApi(fmt"https://api.github.com/repos/daylinmorgan/oizys/actions/runs/{runId}/artifacts")
  fromJson(response.body, ListGhArtifactResponse).artifacts

proc getUpdateSummaryArtifact(runId: int): GhArtifact =
  let name = "summary"
  let artifacts = getArtifacts(runId)
  for artifact in artifacts:
    if artifact.name == name:
      return artifact
  fatalQuit fmt"failed to find summary for run id: {runID}"

proc getUpdateSummaryUrl(runID: int): string =
  ## https://api.github.com/repos/OWNER/REPO/actions/artifacts/ARTIFACT_ID/ARCHIVE_FORMAT
  let artifact = getUpdateSummaryArtifact(runID)
  # httpclient was forwarding the Authorization headers,
  # which confused Azure where the archive lives...
  var response: Response
  try:
    let client = ghClient(maxRedirects = 0)
    response = client.get(artifact.archive_download_url)
  except:
    errorQuit fmt("fetching summary failed:\n\n{response.headers}\n\n{response.body}")

  if "location" notin response.headers.table:
    errorQuit fmt("fetching summary failed:\n\n{response.headers}\n\n{response.body}")

  let location = response.headers.table.getOrDefault("location", @[])
  if location.len == 0: errorQuit fmt("location header missing url?")
  return location[0]

proc fetchUpdateSummaryFromUrl(url: string, host: string): string =
  withTmpDir:
    let client = newHttpClient()
    client.downloadFile(url, tmpDir / "summary.zip")
    let reader = openZipArchive(tmpDir / "summary.zip")
    try:
      result = reader.extractFile(host & "-summary.md")
    finally:
      reader.close()

proc getUpdateSummary*(runId: int, host: string): string =
  withSpinner("fetching update summary"):
    let url = getUpdateSummaryUrl(runId)
    result = fetchUpdateSummaryFromUrl(url, host)

type
  GitRepo = object
    path: string

proc git(r: GitRepo, rest: varargs[string]): Command =
  result.exe = "git"
  result.addArgs ["-C", r.path]
  result.addArgs rest

proc checkGit(code: int) =
  if code != 0: fatalQuit "git had a non-zero exit status"

proc fetch(r: GitRepo) =
  let code = r.git("fetch", "origin").run()
  checkGit code

proc status(r: GitRepo) =
  let (output, _, code) =  r.git("status", "--porcelain").runCapt()
  checkGit code
  if output.len > 0:
    info "unstaged commits, cowardly exiting..."
    quit QuitFailure

proc rebase(r: GitRepo, `ref`: string) =
  r.status()
  let code = r.git("rebase", `ref`).run()
  checkGit code

proc updateRepo*() =
  let repo = GitRepo(path: getFlake())
  fetch repo
  rebase(repo, "origin/flake-lock")

type
  GhPullResponse = object
    id*: int
    state: string
    title: string
    merged: bool
    merge_commit_sha: string

  GhCommit = object
    sha, url: string

  GhBranch = object
    name: string
    commit: GhCommit
    protected: bool

proc getGhPull*(owner: string, repo: string, number: int): GhPullResponse =
  fromJson(
    getGhApi(
      fmt"https://api.github.com/repos/{owner}/{repo}/pulls/{number}"
    ).body,
    typeof(result)
  )


proc getGhBranches*(owner: string, repo: string): seq[GhBranch] =
  # NOTE: there are pages...
  fromJson(
    getGhApi(
      fmt"https://api.github.com/repos/{owner}/{repo}/branches"
    ).body,
    typeof(result)
  )


proc getGhBranch(owner: string, repo: string, branch: string): GhBranch =
  fromJson(
    getGhapi(
      fmt"https://api.github.com/repos/{owner}/{repo}/branches/{branch}"
    ).body,
    typeof(result)
  )

type
  GhCompare = object
    status: string

proc ghRepoCompare(owner: string, repo: string, base: string, head: string): GhCompare =
  fromJson(
    getGhApi(
      fmt"https://api.github.com/repos/{owner}/{repo}/compare/{base}...{head}"
    ).body,
    typeof(result)
  )
  
  # "status": "behind",

proc prInBranch(owner: string, repo: string, branch: GhBranch,  pr: GhPullResponse): bool =
  if not pr.merged:
    return false

  let compare = ghRepoCompare(owner, repo, pr.merge_commit_sha, branch.commit.sha)

  case compare.status:
  of "behind", "identical":
    return false
  of "ahead":
    return true
  of "diverged":
    fatalQuit "compared status of 'diverged' is not yet supported"
  else:
    fatalQuit "unknown status: " & compare.status


type
  NixpkgsPrStatus* = object
    number: int
    merged: bool
    nixpkgsUnstable: bool
    nixosUnstableSmall: bool
    nixosUnstable: bool

proc getNixpkgsPrStatus*(number: int): NixpkgsPrStatus =
  const
    owner = "nixos"
    repo  = "nixpkgs"

  withSpinner(fmt"checking on status of PR [b]#{number}"):

    let pr = getGhPull(owner, repo, number)
    result.number = number
    result.merged = pr.merged

    if result.merged:
      result.nixpkgsUnstable = prInBranch(owner, repo, getGhBranch(owner, repo, "nixpkgs-unstable"),pr)
      result.nixosUnstableSmall = prInBranch(owner, repo, getGhBranch(owner, repo, "nixos-unstable-small"),pr)
      result.nixosUnstable = prInBranch(owner, repo, getGhBranch(owner, repo, "nixos-unstable"), pr)

proc bb*(status: NixpkgsPrStatus): BbString =
  var s: string

  template mark(cond: bool): untyped =
    if cond: "[green]✓[/]" else: "[red]✗[/]"

  s.add fmt"[b]PR #{status.number}[/] status:"

  if not status.merged:
    s.add " not merged"
  else:
    s.add "\n"
    s.add fmt"├──── " & (mark status.nixpkgsUnstable) & " nixpkgs-unstable"
    s.add "\n"
    s.add fmt"├─ " & mark(status.nixosUnstableSmall) & " nixos-unstable-small"
    s.add "\n"
    s.add fmt"╰─ " & mark(status.nixosUnstable) & " nixos-unstable"

  bb(s)

