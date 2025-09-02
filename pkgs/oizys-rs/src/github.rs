use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use reqwest::{
    blocking::{Client, Response},
    header, StatusCode,
};
use serde::de::DeserializeOwned;
use serde::Deserialize;
use std::thread;
use std::time::{Duration, Instant};
use tracing::{debug, info};

#[derive(Deserialize, Debug)]
struct GithubCommit {
    sha: String,
    // url: String,
}

#[derive(Deserialize, Debug)]
struct GithubBranch {
    // name: String,
    commit: GithubCommit,
    // protected: bool,
}

#[derive(Debug, Deserialize)]
struct GithubPullRequest {
    // id: i64,
    // state: String,
    // title: String,
    merged: bool,
    merge_commit_sha: String,
}

#[derive(Deserialize)]
struct GithubCompare {
    status: String,
}

#[derive(Debug)]
#[allow(dead_code)]
pub enum PrStatus {
    NotMerged,
    Merged {
        nixpkgs_unstable: bool,
        nixos_unstable_small: bool,
        nixos_unstable: bool,
    },
}

// one of these attributes was causing a parser error?
#[derive(Deserialize, Debug, Clone)]
struct GithubWorkflowRun {
    id: i64,
    //node_id: String,
    //run_number: i64,
    //event: String,
    status: String,
    //conclusion: String,
    //html_url: String,
    //workflow_id: i64,
    created_at: DateTime<Utc>,
    //updated_at: String,
}

#[derive(Deserialize, Debug)]
struct ListGithubWorflowRun {
    //    total_count: i64,
    workflow_runs: Vec<GithubWorkflowRun>,
}

static APP_USER_AGENT: &str = concat!(env!("CARGO_PKG_NAME"), "/", env!("CARGO_PKG_VERSION"),);

fn handle_response<T: DeserializeOwned>(resp: Response) -> Result<T> {
    match resp.status() {
        StatusCode::OK => {
            let data: T = resp.json()?;
            return Ok(data);
        }
        s => bail!(
            "github api had an unexpected error: {s:?}, see below:\n{}",
            resp.text()?
        ),
    };
}

struct GitHubRepo {
    client: Client,
    owner: String,
    repo: String,
}

impl GitHubRepo {
    fn new_client() -> Result<Client> {
        // --header "Authorization: Bearer YOUR-TOKEN" \
        // --header "X-GitHub-Api-Version: 2022-11-28"

        let mut headers = header::HeaderMap::new();
        if let Ok(token) = std::env::var("GITHUB_TOKEN") {
            info!("using GITHUB_TOKEN for API requests");
            let token = "Bearer ".to_string() + &token;
            let mut token = header::HeaderValue::from_str(&token)?;
            token.set_sensitive(true);
            headers.insert("Authorization", token);
        } else {
            info!("set env var GITHUB_TOKEN to use authenticated requests")
        }
        headers.insert(
            "X-GitHub-Api-Version",
            header::HeaderValue::from_static("2022-11-28"),
        );
        headers.insert(
            "Accept",
            header::HeaderValue::from_static("application/vnd.github+json"),
        );
        Ok(Client::builder()
            .user_agent(APP_USER_AGENT)
            .default_headers(headers)
            .build()?)
    }
    fn new(owner: &str, repo: &str) -> Result<Self> {
        let client = Self::new_client()?;
        Ok(Self {
            client,
            owner: owner.to_string(),
            repo: repo.to_string(),
        })
    }

    fn get<T: DeserializeOwned>(&self, url: &str) -> Result<T> {
        debug!("GET: {}", url);
        let resp = self.client.get(url).send()?;
        handle_response(resp)
    }

    fn get_branch(&self, branch: &str) -> Result<GithubBranch> {
        self.get(&format!(
            "https://api.github.com/repos/{}/{}/branches/{}",
            self.owner, self.repo, branch
        ))
    }

    fn get_pr(&self, number: i64) -> Result<GithubPullRequest> {
        self.get(&format!(
            "https://api.github.com/repos/{}/{}/pulls/{}",
            self.owner, self.repo, number
        ))
    }

    fn compare_branch_to_pr(&self, base: &str, head: &str) -> Result<GithubCompare> {
        self.get(&format!(
            "https://api.github.com/repos/{}/{}/compare/{}...{}",
            self.owner, self.repo, base, head
        ))
    }
    fn pr_in_branch(&self, branch: &str, pr: &GithubPullRequest) -> Result<bool> {
        if !pr.merged {
            return Ok(false);
        }

        let branch = self.get_branch(branch)?;
        let compare = self.compare_branch_to_pr(&pr.merge_commit_sha, &branch.commit.sha)?;

        match compare.status.as_str() {
            "behind" | "identical" => Ok(false),
            "ahead" => Ok(true),
            "diverged" => bail!("compared status of 'diverged' is not yet supported"),
            s => bail!("unknown status {s}"),
        }
    }

    /// TODO: accept abritrary 'inputs' as json
    fn run_action(&self, workflow: &str, ref_name: &str) -> Result<()> {
        let mut body = std::collections::HashMap::new();
        let url = format!(
            "https://api.github.com/repos/{}/{}/actions/workflows/{}/dispatches",
            self.owner, self.repo, workflow
        );

        info!("POST: {}", url);
        body.insert("ref", ref_name); // main should be an argument from CLI...
        let res = self.client.post(url).json(&body).send()?;
        match res.status() {
            StatusCode::NO_CONTENT => Ok(()),
            StatusCode::NOT_FOUND => {
                bail!(
                    "workflow does not exist, see below for API reponse:\n{:?}",
                    &res
                )
            }
            _ => bail!("possible error submitting post request {:?}", &res),
        }
    }

    fn normalize_workflow(name: &str) -> String {
        if !name.ends_with(".yml") && !name.ends_with(".yaml") {
            name.to_string() + ".yml" // I use .yml only
        } else {
            name.to_string()
        }
    }

    fn list_workflow_runs(&self, workflow: &str) -> Result<ListGithubWorflowRun> {
        self.get(&format!(
            "https://api.github.com/repos/{}/{}/actions/workflows/{}/runs",
            self.owner, self.repo, workflow
        ))
    }

    fn is_current_run(run: &GithubWorkflowRun, now: &DateTime<Utc>) -> bool {
        ["in_progress", "queued"].contains(&run.status.as_str()) && run.created_at > *now
    }

    fn get_in_progress_run(
        &self,
        workflow: &str,
        now: &DateTime<Utc>,
    ) -> Result<GithubWorkflowRun> {
        let start_time = Instant::now();
        let interval = Duration::from_millis(500);

        info!("waiting up to 10 seconds for workflow to start");
        while start_time.elapsed() < Duration::from_secs(10) {
            let runs = self.list_workflow_runs(&workflow)?.workflow_runs;
            let latest = &runs[0];
            if Self::is_current_run(latest, &now) {
                return Ok(runs[0].clone());
            }
            thread::sleep(interval);
        }

        bail!(
            "timeout while trying to get running action for {:}",
            &workflow
        )
    }
}

pub fn get_nixpkgs_pr_status(pr_number: i64) -> Result<PrStatus> {
    let repo = GitHubRepo::new("nixos", "nixpkgs")?;
    let pr = repo.get_pr(pr_number)?;
    if !pr.merged {
        return Ok(PrStatus::NotMerged);
    }
    let status = PrStatus::Merged {
        nixpkgs_unstable: repo.pr_in_branch("nixos-unstable", &pr)?,
        nixos_unstable_small: repo.pr_in_branch("nixos-unstable-small", &pr)?,
        nixos_unstable: repo.pr_in_branch("nixos-unstable", &pr)?,
    };
    Ok(status)
}

pub fn oizys_gha_run(workflow: &str, ref_name: &str) -> Result<()> {
    let repo = GitHubRepo::new("daylinmorgan", "oizys")?;
    let workflow = GitHubRepo::normalize_workflow(&workflow);
    let now: DateTime<Utc> = Utc::now();
    repo.run_action(&workflow, &ref_name)?;
    let run = repo.get_in_progress_run(&workflow, &now)?;
    println!(
        "view workflow run at: https://github.com/daylinmorgan/oizys/actions/runs/{}",
        run.id
    );
    Ok(())
}
