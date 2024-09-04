import std/[httpclient,logging, os, strformat, strutils, json]

var ghToken = getEnv("GITHUB_TOKEN")

#[curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR-TOKEN>" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/WORKFLOW_ID/dispatches \
  -d '{"ref":"topic-branch","inputs":{"name":"Mona the Octocat","home":"San Francisco, CA"}}'
]#

proc postGhApi(url: string, body: JsonNode) =
  if ghToken == "": fatal "GITHUB_TOKEN not set"; quit QuitFailure
  let client = newHttpClient()
  client.headers = newHttpHeaders({
    "Accept"              : "application/vnd.github+json",
    "Authorization"       : fmt"Bearer {ghToken}",
    "X-GitHub-Api-Version": "2022-11-28",
  })
  let response = client.post(url, body = $body)
  try:
    info fmt"Status: {response.code}"
  except:
    error "failed to get response code"

proc createDispatch*(workflowFileName: string, `ref`: string) =
  ## https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
  var workflow =
    if workflowFileName.endsWith(".yml") or workflowFileName.endsWith(".yaml"): workflowFileName
    else: workflowFileName & ".yml"
  info fmt"creating dispatch event for {workflow}"
  postGhApi(
   fmt"https://api.github.com/repos/daylinmorgan/oizys/actions/workflows/{workflow}/dispatches",
    %*{
      "ref": `ref`,
    }
  )


