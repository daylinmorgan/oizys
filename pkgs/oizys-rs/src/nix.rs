use super::prelude::*;
use super::process::LoggedCommand;
use clap::ValueEnum;
use std::collections::{BTreeMap, HashSet};
use tracing::{debug, info};

#[derive(Debug, Clone, ValueEnum)]
pub enum NixName {
    Pinix,
    Nom,
    Nix,
}

impl std::fmt::Display for NixName {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            NixName::Pinix => write!(f, "pix"),
            NixName::Nom => write!(f, "nom"),
            NixName::Nix => write!(f, "nix"),
        }
    }
}

#[derive(Debug)]
pub struct NixCommand {
    bin: String,
    bootstrap: bool,
}

fn exists_or<'a>(bin: &'a str, fallback: &'a str) -> &'a str {
    match which::which(&bin) {
        Ok(_) => bin,
        Err(_) => {
            info!("{bin} not found falling back to {fallback}");
            fallback
        }
    }
}

impl NixName {
    fn choose(&self) -> String {
        let bin = self.to_string();
        match self {
            NixName::Nix => bin,

            _ => exists_or(&bin, "nix").to_string(),
        }
    }
    fn choose_nixos_rebuild(&self) -> String {
        let name = match self {
            NixName::Nom | NixName::Nix => "nixos-rebuild",
            NixName::Pinix => exists_or("pixos-rebuild", "nixos-rebuild"),
        };
        name.to_string()
    }
}

impl NixCommand {
    pub fn new(name: &NixName, bootstrap: bool) -> Self {
        Self {
            bin: if !bootstrap {
                name.choose()
            } else {
                "nix".to_string()
            },
            bootstrap,
        }
    }

    #[cfg(feature = "substituters")]
    pub fn cmd(&self) -> LoggedCommand {
        let mut cmd = LoggedCommand::new(&self.bin.clone());
        if self.bootstrap {
            super::substituters::apply_subsituter_flags(&mut cmd);
        }
        cmd
    }

    #[cfg(not(feature = "substituters"))]
    pub fn cmd(&self) -> LoggedCommand {
        if self.bootstrap {
            tracing::error!("build with nix (and 'substituters' feature) for bootstrap support");
        }
        LoggedCommand::new(&self.bin.clone())
    }

    pub fn build(&self, installables: Vec<String>) -> Result<()> {
        let mut cmd = self.cmd();
        cmd.arg("build").args(installables);
        cmd.check_status().wrap_err("nix build failed")
    }

    pub fn nix(&self) -> LoggedCommand {
        Self::new(&NixName::Nix, self.bootstrap).cmd()
    }

    pub fn build_dry_run(&self, installables: &Vec<String>) -> Result<String> {
        let stderr = self
            .nix()
            .arg("build")
            .args(installables)
            .arg("--dry-run")
            .stderr_ok()?;
        Ok(stderr)
    }

    // TODO: support nix-eval-jobs for this method
    pub fn not_cached(&self, installables: &Vec<String>) -> Result<Vec<String>> {
        let span = bar_span!("checking for missing packages").entered();
        let stderr = self.build_dry_run(installables)?;
        span.exit();
        let drvs = extract_drvs(&stderr)?;
        Ok(drvs)
    }

    // NOTE this could (and should) be async
    pub fn build_drvs_multi(&self, drvs: &Vec<String>) -> Result<Vec<String>> {
        let mut results = vec![];
        for d in drvs {
            info!("building: {}", d);
            let stdout = NixCommand::new(&NixName::Nix, self.bootstrap)
                .cmd()
                .arg("build")
                .arg(format!("{}^*", d))
                .arg("--print-out-paths")
                .stdout_ok()?;
            results.push(stdout.lines().map(|s| s.to_string()).collect());
        }
        Ok(results)
    }
}

use serde::Deserialize;

#[derive(Debug, Deserialize, Eq, Hash, PartialEq)]
pub struct NixEvalOutput {
    name: String,
    #[serde(rename = "drvPath")]
    drv_path: String,
    #[serde(rename = "isCached")]
    is_cached: bool,
    outputs: BTreeMap<String, String>,
}

pub fn get_not_cached_nix_eval_jobs(flake: &str, hosts: &Vec<String>) -> Result<Vec<String>> {
    let ignored_names = ignored_names();
    let args = ["--flake", "--check-cache-status"];
    let mut stdout = "".to_string();
    for host in hosts {
        let out = LoggedCommand::new("nix-eval-jobs")
            .args(args)
            .arg(format!(
                "{flake}#nixosConfigurations.{host}.config.oizys.packages"
            ))
            .stdout_ok()?;
        stdout.push_str(&out);
    }

    let mut drvs = HashSet::new();
    let mut ignored = HashSet::new();
    for line in stdout.lines() {
        let drv: NixEvalOutput = serde_json::from_str(line).wrap_err(format!("line: {}", line))?;
        if !drv.is_cached {
            if !is_ignored(&drv.name, &ignored_names) {
                drvs.insert(drv);
            } else {
                ignored.insert(drv);
            }
        }
    }
    if !ignored.is_empty() {
        info!("ignored {} derivations", ignored.len());
        debug!("ignored derviations:\n{:?}", ignored);
    }
    Ok(drvs.iter().map(|d| d.drv_path.to_string()).collect())
}

// NixEvalOutput = object
//   name: string
//   drvPath: string
//   isCached: bool
//   outputs: Table[string, string]
//
/*proc missingDrvNixEvalJobs*(): HashSet[NixEvalOutput] =
  ## get all derivations not cached using nix-eval-jobs
  var cmd = newCommand("nix-eval-jobs", "--flake", "--check-cache-status")
  var output: string

  for host in getHosts():
    let flakeUrl = getFlake() & "#nixosConfigurations." & host & ".config.oizys.packages"
    let (o, _) = cmd
      .withArgs(flakeUrl)
      .runCaptSpin(bb"running [b]nix-eval-jobs[/] for " & host.bb("bold"))
    output.add o

  var cached: HashSet[NixEvalOutput]
  var ignored: HashSet[NixEvalOutput]

  for line in output.strip().splitLines():
    let output = line.fromJson(NixEvalOutput)
    if output.isCached:
      cached.incl output
    elif output.name.isIgnored():
      ignored.incl output
    else:
      result.incl output

  debug "cached derivations: ", bb($cached.len, "yellow")
  debug "ignored derivations: ", bb($ignored.len, "yellow")

*/

pub fn push_to_attic_cache(drvs: Vec<String>, name: &str) -> Result<()> {
    LoggedCommand::new("attic")
        .arg("push")
        .arg(name)
        .args(drvs)
        .check_status()
}

const IGNORED_RAW_TEXT: &str = include_str!("ignored.txt");

/// parse a plaintext list of packages
/// ignore empty lines and lines starting with '#'
fn ignored_names() -> Vec<String> {
    IGNORED_RAW_TEXT
        .lines()
        .filter(|line| !line.trim().is_empty() && !line.trim().starts_with('#'))
        .map(|line| line.trim().to_string())
        .collect()
}

fn is_ignored(name: &str, ignored: &Vec<String>) -> bool {
    for n in ignored {
        if name.starts_with(n) {
            return true;
        }
    }
    return false;
}

pub fn extract_drvs(nix_output: &str) -> Result<Vec<String>> {
    let re = regex::Regex::new(r"(?m)^\s+/nix/store/(?<hash>.{32})-(?<name>.*)\.drv$")?;
    let ignored = ignored_names();
    let results: Vec<String> = re
        .captures_iter(nix_output)
        .map(|c| c.extract())
        .filter(|(_full, [_hash, name])| !is_ignored(&name, &ignored))
        .map(|(full, [_hash, _name])| String::from(full).trim().to_string())
        .collect();
    Ok(results)
}

pub struct Nixos {
    pub flake: String,
    pub host: String,
}

impl Nixos {
    pub fn new(flake: &str, host: &str) -> Self {
        let host = host.to_string();
        let flake = flake.to_string();
        Self { host, flake }
    }

    pub fn attr(&self) -> String {
        format!(
            "{}#nixosConfigurations.{}.config.system.build.toplevel",
            self.flake, self.host
        )
    }

    pub fn system_attr(&self) -> String {
        format!(
            "{}#nixosConfigurations.{}.config.system.path",
            self.flake, self.host
        )
    }

    pub fn rebuild(&self, nix: NixName, subcmd: &str, extra_flags: Vec<String>) -> Result<()> {
        let attr = format!("{}#{}", self.flake, self.host);

        LoggedCommand::new("sudo")
            .arg(nix.choose_nixos_rebuild())
            .arg(subcmd)
            .arg("--flake")
            .arg(attr)
            .args(extra_flags)
            .check_status()
            .wrap_err("nixos-rebuild failed")?;

        if subcmd == "switch" {
            info!("check chezmoi status");
            let stdout = LoggedCommand::new("chezmoi").arg("status").stdout_ok()?;
            if stdout != "" {
                println!(
                    "fyi the dotfiles don't match, see below:\n{}",
                    &super::indent(stdout)
                )
            }
        }

        Ok(())
    }
}

pub fn set_flake(flake: Option<String>) -> Result<String> {
    if let Some(flake) = flake {
        return Ok(flake);
        // let the value be arbitrary
        // let path = std::path::PathBuf::from(&flake);
        // if path.is_dir() {
        //     return Ok(flake);
        // }
        // } else {
        //     bail!("path does not exist: {}", path.display());
        // }
    }

    if let Ok(path) = std::env::var("OIZYS_DIR") {
        return Ok(path);
    };

    let path = std::env::home_dir().unwrap().join("oizys");
    if path.is_dir() {
        return Ok(path.into_os_string().into_string().unwrap());
    }

    info!("{:?} does not exist, using remote as fallback", path);
    Ok("github:daylinmorgan/oizys".to_string())
}

/// check if some flake exists
fn needs_to_be_built(flake: &str) -> Result<bool> {
    let output = LoggedCommand::new("nix")
        .arg("path-info")
        .arg(&flake)
        .output()?;
    Ok(!output.status.success())
}

// TODO: better error handling here
pub fn run_current(nix: &NixCommand, flake: &str, args: Vec<String>) {
    let flake = format!("{flake}#oizys-rs");
    let to_build =
        needs_to_be_built(&flake).expect(&format!("failed to check path-info of: {}", &flake));
    if to_build {
        nix.cmd()
            .arg("build")
            .arg(&flake)
            .arg("--no-link")
            .check_status()
            .expect("failed to pre-build oizys");
    }

    let err = LoggedCommand::new("nix")
        .arg("run")
        .arg(&flake)
        .arg("--")
        .args(args)
        .exec();

    // The code below will only be executed if `exec` fails.
    println!(
        "{}: {} {}:\n{}",
        style("ERROR").red(),
        style("oizys self").bold().yellow(),
        style("has failed...this shouldn't happen, see below for more info").red(),
        err
    );
    std::process::exit(1);
}
