use super::prelude::*;
use chrono::{DateTime, Utc};
use reqwest::{
    blocking::{Client, Response},
    header, StatusCode,
};
use serde::Deserialize;
use serde::{de::DeserializeOwned, Serialize};
use std::time::{Duration, Instant};
use std::{collections::HashMap, thread};
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
pub enum PrStatus {
    NotMerged,
    Merged {
        nixpkgs_unstable: bool,
        nixos_unstable_small: bool,
        nixos_unstable: bool,
    },
}

fn style_branch(name: &str, merged: &bool) -> String {
    let branch = style(name);
    let branch = if *merged {
        branch.green()
    } else {
        branch.red()
    };
    branch.to_string()
}
impl std::fmt::Display for PrStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Self::NotMerged => writeln!(f, "{}", style("not merged").red())?,
            Self::Merged {
                nixpkgs_unstable,
                nixos_unstable_small,
                nixos_unstable,
            } => {
                writeln!(
                    f,
                    "-> {}",
                    style_branch("nixpkgs-unstable", nixpkgs_unstable)
                )?;
                writeln!(
                    f,
                    "-> {}",
                    style_branch("nixos-unstable-small", nixos_unstable_small)
                )?;
                writeln!(f, "-> {}", style_branch("nixos-unstable", nixos_unstable))?;
            }
        }

        Ok(())
    }
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
        let mut headers = header::HeaderMap::new();
        if let Ok(token) = std::env::var("GITHUB_TOKEN") {
            debug!("using GITHUB_TOKEN for API requests");
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

    fn run_action(
        &self,
        workflow: &str,
        ref_name: &str,
        inputs: Vec<(String, String)>,
    ) -> Result<()> {
        let url = format!(
            "https://api.github.com/repos/{}/{}/actions/workflows/{}/dispatches",
            self.owner, self.repo, workflow
        );
        debug!("POST: {}", url);
        let body = GithubWorkflowDispatchBody::new(&ref_name, inputs)?;
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
        let _span = bar_span!("waiting for workflow to start").entered();
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

#[derive(Debug, Serialize)]
struct GithubWorkflowDispatchBody {
    #[serde(rename = "ref")]
    ref_name: String,

    inputs: HashMap<String, String>,
}

impl GithubWorkflowDispatchBody {
    fn inputs_to_hashmap(inputs: Vec<(String, String)>) -> Result<HashMap<String, String>> {
        let mut map = HashMap::new();
        for (k, v) in &inputs {
            let v = if !v.starts_with("@") {
                v
            } else {
                info!("populating input '{}' with contents from {}", k, &v[1..]);
                &std::fs::read_to_string(&v[1..])
                    .wrap_err(format!("failed to read file {}", &v[1..]))?
            };
            map.insert(k.to_owned(), v.to_owned());
        }
        Ok(map)
    }

    fn new(ref_name: &str, inputs: Vec<(String, String)>) -> Result<Self> {
        let ref_name = ref_name.to_string();
        let inputs =
            Self::inputs_to_hashmap(inputs).wrap_err("failed to generate github workflow body")?;
        Ok(Self { ref_name, inputs })
    }
}

pub fn get_nixpkgs_pr_status(pr_number: i64) -> Result<PrStatus> {
    let repo = GitHubRepo::new("nixos", "nixpkgs")?;
    let pr = repo.get_pr(pr_number)?;
    let status = if !pr.merged {
        PrStatus::NotMerged
    } else {
        PrStatus::Merged {
            nixpkgs_unstable: repo.pr_in_branch("nixos-unstable", &pr)?,
            nixos_unstable_small: repo.pr_in_branch("nixos-unstable-small", &pr)?,
            nixos_unstable: repo.pr_in_branch("nixos-unstable", &pr)?,
        }
    };
    Ok(status)
}

pub fn oizys_gha_run(workflow: &str, ref_name: &str, inputs: Vec<(String, String)>) -> Result<i64> {
    let _span = bar_span!("dispatching github action").entered();
    let repo = GitHubRepo::new("daylinmorgan", "oizys")?;
    let workflow = GitHubRepo::normalize_workflow(&workflow);
    let now: DateTime<Utc> = Utc::now();
    repo.run_action(&workflow, &ref_name, inputs)
        .wrap_err("failed to start action")?;
    let run = repo.get_in_progress_run(&workflow, &now)?;
    Ok(run.id)
}
