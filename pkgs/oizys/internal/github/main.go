package github

import (
	"archive/zip"
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"oizys/internal/oizys"
	"strings"

	"github.com/charmbracelet/log"
	"github.com/google/go-github/v63/github"
)

var client *github.Client

func init() {
	client = github.NewClient(nil).WithAuthToken(oizys.GithubToken())
}

func ListWorkflows() {
	workflowRuns, resp, err := client.Actions.ListWorkflowRunsByFileName(
		context.Background(),
		"daylinmorgan",
		"oizys",
		"update.yml",
		nil,
	)
	if err != nil {
		log.Fatal("Failed to get a list of workflows", "err", err, "resp", resp)
	}
	for _, w := range workflowRuns.WorkflowRuns {
		fmt.Println(w.GetID())
		fmt.Println(w.GetConclusion())
	}
}

func ListUpdateRuns() (*github.WorkflowRuns, *github.Response) {
	workflowRuns, resp, err := client.Actions.ListWorkflowRunsByFileName(
		context.Background(),
		"daylinmorgan",
		"oizys",
		"update.yml",
		nil,
	)
	if err != nil {
		log.Fatal("failed to get last update run", "resp", resp, "err", err)
	}

	return workflowRuns, resp
}

func GetArtifacts(runID int64) (*github.ArtifactList, *github.Response) {
	artifactList, resp, err := client.Actions.ListWorkflowRunArtifacts(context.Background(), "daylinmorgan", "oizys", runID, nil)
	if err != nil {
		log.Fatal("failed to get artifacts for run", "id", runID, "err", err)
	}
	return artifactList, resp
}

func GetUpdateSummaryArtifact(runID int64, host string) *github.Artifact {
	artifactName := fmt.Sprintf("%s-summary", host)
	artifactList, _ := GetArtifacts(runID)
	for _, artifact := range artifactList.Artifacts {
		if artifact.GetName() == artifactName {
			return artifact
		}
	}
	log.Fatal("failed to find summary for run", "id", runID)
	return nil
}

func GetUpdateSummaryUrl(runID int64, host string) *url.URL {
	artifact := GetUpdateSummaryArtifact(runID, host)
	url, resp, err := client.Actions.DownloadArtifact(context.Background(), "daylinmorgan", "oizys", artifact.GetID(), 4)
	if err != nil {
		log.Fatal("failed to get update summary URL", "artifact", artifact.GetID(), "resp", resp)
	}
	return url
}

func GetUpdateSummaryFromUrl(url *url.URL) []byte {
	log.Debug(url.String())
	res, err := http.Get(url.String())
	if err != nil {
		log.Fatal("failed to get update summary zip", "err", err)
	}
	body, err := io.ReadAll(res.Body)
	res.Body.Close()
	if res.StatusCode > 299 {
		log.Fatalf("Response failed with status code: %d and\nbody: %s\n", res.StatusCode, body)
	}
	if err != nil {
		log.Fatal(err)
	}
	return body
}

func GetLastUpdateRun() *github.WorkflowRun {
	workflowRuns, _ := ListUpdateRuns()
	run := workflowRuns.WorkflowRuns[0]
	if run.GetConclusion() == "failure" {
		log.Fatal("Most recent run was not successful", "runId", run.GetID(), "conclusion", run.GetConclusion())
	}
	if run.GetStatus() == "in_progress" {
		log.Fatalf("Most recent run is not finished\nview workflow run at: %s", run.GetHTMLURL())
	}
	return run
}

func GetUpateSummary(runID int64, host string) (string, error) {
	url := GetUpdateSummaryUrl(runID, host)
	bytes := GetUpdateSummaryFromUrl(url)
	md, err := ReadMarkdownFromZip(bytes, "summary.md")
	return md, err
}

func ReadMarkdownFromZip(zipData []byte, fileName string) (string, error) {
	// Open the zip reader from the in-memory byte slice
	reader, err := zip.NewReader(bytes.NewReader(zipData), int64(len(zipData)))
	if err != nil {
		return "", err
	}

	// Search for the target file
	var markdownFile *zip.File
	for _, f := range reader.File {
		if f.Name == fileName {
			markdownFile = f
			break
		}
	}

	if markdownFile == nil {
		return "", fmt.Errorf("file %s not found in zip archive", fileName)
	}

	// Open the markdown file reader
	fileReader, err := markdownFile.Open()
	if err != nil {
		return "", err
	}
	defer fileReader.Close()

	// Read the markdown content
	content, err := io.ReadAll(fileReader)
	if err != nil {
		return "", err
	}

	// Return the markdown content as string
	return string(content), nil
}

func CreateDispatch(workflowFileName string, ref string, inputs map[string]interface{}) {
	if !strings.HasSuffix(workflowFileName, ".yml") && !strings.HasSuffix(workflowFileName, ".yaml") {
		workflowFileName = workflowFileName + ".yml"
	}
	log.Infof("creating dispatch event for %s", workflowFileName)
	event := github.CreateWorkflowDispatchEventRequest{Ref: ref, Inputs: inputs}
	_, err := client.Actions.CreateWorkflowDispatchEventByFileName(
		context.Background(),
		"daylinmorgan",
		"oizys",
		workflowFileName,
		event,
	)
	if err != nil {
		log.Fatal("failed to dispatch event", "filename", workflowFileName, "err", err)
	}
}
