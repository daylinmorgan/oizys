import std/[httpclient,logging, os, strformat, strutils, json, tables, tempfiles, times]
import jsony, hwylterm, hwylterm/logging, zippy/ziparchives
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
    error fmt"github api request failed: {url}"
    error fmt"response: {result.body}"
    quit QuitFailure

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
  if response.code != Http204:
    errorQuit "failed to post github api request"

proc getInProgressRun(
  workflow: string,
  timeout: int = 10000
): (GhWorkflowRun, bool) =
  ## wait up to 10 seconds to try to fetch ongoing run url
  let
    start = now()
    timeoutDuration = initDuration(milliseconds = timeout)

  withSpinner fmt"waiting for {workflow} workflow to start":
    while (now() - start) < timeoutDuration:
      let response = getGhApi(fmt"https://api.github.com/repos/daylinmorgan/oizys/actions/workflows/{workflow}/runs")
      let runs = fromJson(response.body,  ListGhWorkflowResponse).workflow_runs
      if runs[0].status in ["in_progress", "queued"]:
        spinner.stop() # cleanup
        return (runs[0], true)
      sleep 500

  warn "timeout reached waiting for workflow to start"

proc createDispatch*(workflowFileName: string, `ref`: string, inputs: Table[string, string]) =
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
  let (run, ok) = getInProgressRun(workflow)
  if ok: info "view workflow run at: " & run.html_url

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

proc git(r: GitRepo, rest: varargs[string]): string =
  result = "git"
  result.addArgs ["-C", r.path]
  result.addArgs rest

proc checkGit(code: int) =
  if code != 0: fatalQuit "git had a non-zero exit status"

proc fetch(r: GitRepo) =
  let code = runCmd r.git("fetch", "origin")
  checkGit code

proc status(r: GitRepo) =
  let (output, _, code) = runCmdCapt r.git("status", "--porcelain")
  checkGit code
  if output.len > 0:
    info "unstaged commits, cowardly exiting..."
    quit QuitFailure

proc rebase(r: GitRepo, `ref`: string) =
  r.status()
  let code = runCmd r.git("rebase", `ref`)
  checkGit code

proc updateRepo*() =
  let repo = GitRepo(path: getFlake())
  fetch repo
  rebase(repo, "origin/flake-lock")
