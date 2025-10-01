use crate::prelude::*;
use crate::{process::LoggedCommand, ui};
use clap::ValueEnum;
use reqwest::{blocking::Client, StatusCode};
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
            tracing::warn!("{bin} not found falling back to {fallback}");
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
    pub fn default() -> Self {
        Self {
            bin: "nix".to_string(),
            bootstrap: false,
        }
    }
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
            crate::substituters::apply_subsituter_flags(&mut cmd);
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

    pub async fn build_drvs_multi(&self, drvs: Vec<String>) -> Result<Vec<String>> {
        let drv_names = drvs
            .iter()
            .map(|d| d[11..d.len() - 4].to_string())
            .collect::<Vec<_>>()
            .join(", ");
        debug!("building {} derivations: {:}", drvs.len(), drv_names);
        let tasks: Vec<_> = drvs
            .into_iter()
            .map(|d| {
                debug!("building {}", &d);
                tokio::spawn(async move {
                    tokio::process::Command::new("nix")
                        .arg("build")
                        .arg(format!("{}^*", &d))
                        .arg("--print-out-paths")
                        .arg("--no-link")
                        .output()
                        .await
                })
            })
            .collect();

        let results = futures::future::join_all(tasks).await;
        let mut to_push = vec![];
        for result in results {
            let output = result.wrap_err("task failure")?.wrap_err("Command error")?;
            if output.status.success() {
                to_push.extend(
                    String::from_utf8(output.stdout)?
                        .trim()
                        .lines()
                        .map(String::from),
                );
            } else {
                tracing::error!(
                    "nix build failure:\n{}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }

        Ok(to_push)
    }

    pub fn flake_update(&self) -> Result<()> {
        self.nix()
            .arg("flake")
            .arg("update")
            .arg("--output-lock-file")
            .arg("updated.lock")
            .check_status()
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

pub struct AtticCache {
    name: String,
}

impl AtticCache {
    pub fn new(name: &str) -> Self {
        let name = name.to_string();
        Self { name }
    }

    pub fn push(&self, drvs: Vec<String>) -> Result<()> {
        LoggedCommand::new("attic")
            .arg("push")
            .arg(&self.name)
            .args(drvs)
            .check_status()
    }
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
    ignored.iter().any(|n| name.starts_with(n))
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

#[derive(Debug)]
pub struct Nixos {
    pub flake: String,
    pub host: String,
}

impl Nixos {
    pub fn new_multi(flake: &str, hosts: &Vec<String>) -> Vec<Self> {
        hosts.iter().map(|h| Self::new(&flake, &h)).collect()
    }
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

    pub fn build_with_args<I, S>(&self, args: I) -> Result<()>
    where
        I: IntoIterator<Item = S>,
        S: AsRef<std::ffi::OsStr>,
    {
        NixCommand::default()
            .cmd()
            .arg("build")
            .arg(self.attr())
            .args(args)
            .check_status()
    }

    pub fn rebuild(&self, nix: NixName, subcmd: &str, extra_flags: Vec<String>) -> Result<()> {
        let attr = format!("{}#{}", self.flake, self.host);

        // use nix/nom build if it's subcmd == switch?

        LoggedCommand::new("sudo")
            .arg(nix.choose_nixos_rebuild())
            .arg(subcmd)
            .arg("--flake")
            .arg(attr)
            .args(extra_flags)
            .check_status()
            .wrap_err("nixos-rebuild failed")?;

        if subcmd == "switch" {
            chezmoi_status()?;
        }

        Ok(())
    }

    fn oizys_packages_attr(&self) -> String {
        format!(
            "{}#nixosConfigurations.{}.config.oizys.packages",
            self.flake, self.host
        )
    }

    pub fn not_cached_system_path(&self) -> Result<HashSet<NixEvalOutput>> {
        let _span =
            tracing::info_span!(target: "oizys::bar", "running nix-eval-jobs", host = self.host)
                .entered();
        let stdout = LoggedCommand::new("nix-eval-jobs")
            .arg("--flake")
            .arg("--check-cache-status")
            .arg(self.oizys_packages_attr())
            .stdout_ok()?;

        let mut drvs = HashSet::new();
        for line in stdout.lines() {
            let drv: NixEvalOutput =
                serde_json::from_str(line).wrap_err(format!("failed to parse line: {}", line))?;
            if !drv.is_cached {
                drvs.insert(drv);
            }
        }
        Ok(drvs)
    }
}

pub trait NixosOps {
    fn not_cached(&self) -> Result<Vec<String>>;
    fn build_update_build(&self) -> Result<()>;
}

impl NixosOps for Vec<Nixos> {
    fn not_cached(&self) -> Result<Vec<String>> {
        let _span = bar_span!("checking for packages that need to be built").entered();
        let mut drvs: HashSet<NixEvalOutput> = HashSet::new();
        for system in self {
            for d in system.not_cached_system_path()? {
                drvs.insert(d);
            }
            // why doesn't union work?
            // drvs = drvs.union(&not_cached).collect();
        }

        let ignored_names = ignored_names();
        let mut to_build = HashSet::new();
        let mut ignored = HashSet::new();
        for drv in drvs {
            if !is_ignored(&drv.name, &ignored_names) {
                to_build.insert(drv);
            } else {
                ignored.insert(drv);
            }
        }
        if !ignored.is_empty() {
            let names: Vec<String> = ignored.iter().map(|d| d.name.to_string()).collect();
            info!("ignored {} derivations", ignored.len());
            debug!("ignored derviations:\n{:?}", names);
        }

        Ok(to_build.iter().map(|d| d.drv_path.to_string()).collect())
    }

    // should this be reduced to two nix build commands?
    fn build_update_build(&self) -> Result<()> {
        for system in self {
            info!("building current system {:?}", system);
            system.build_with_args(["--out-link", &format!("{}-current", system.host)])?;
        }

        NixCommand::default().flake_update()?;

        for system in self {
            info!("building updated system {:?}", system);
            system.build_with_args([
                "--out-link",
                &format!("{}-updated", system.host),
                "--reference-lock-file",
                "updated.lock",
            ])?;
        }
        Ok(())
    }
}

/// check if some flake exists
fn needs_to_be_built(flake: &str) -> Result<bool> {
    let output = LoggedCommand::new("nix")
        .arg("path-info")
        .arg(&flake)
        .output()?;
    Ok(!output.status.success())
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
        if path != "" {
            return Ok(path);
        }
    };

    let path = std::env::home_dir().unwrap().join("oizys");
    if path.is_dir() {
        return Ok(path.into_os_string().into_string().unwrap());
    }

    info!("{:?} does not exist, using remote as fallback", path);
    Ok("github:daylinmorgan/oizys".to_string())
}

// TODO: better error handling here
pub fn run_current(nix: &NixCommand, flake: &str, args: Vec<String>) {
    let flake = format!("{flake}#oizys");
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

#[derive(Debug, Hash, Eq, PartialEq)]
pub struct NixCache {
    url: String,
}

impl std::fmt::Display for NixCache {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> Result<(), std::fmt::Error> {
        write!(f, "Cache({})", &self.url)?;
        Ok(())
    }
}

impl NixCache {
    pub fn from(s: &str) -> Self {
        Self {
            url: s.trim_end_matches('/').into(),
        }
    }

    pub fn search(&self, hash: &str) -> Result<Option<String>> {
        let url = format!("{}/{}.narinfo", self.url, hash);
        let client = Client::builder().user_agent(APP_USER_AGENT).build()?;
        debug!("GET: {}", url);
        let resp = client.get(url).send()?;
        match resp.status() {
            StatusCode::OK => return Ok(Some(resp.text()?)),
            StatusCode::NOT_FOUND => return Ok(None),
            _ => bail!("unexpected failure, {:?}", resp),
        }
    }
}

pub trait Cache {
    fn search(&self, hashes: Vec<String>, all: bool) -> Result<()>;
}

impl Cache for HashSet<NixCache> {
    fn search(&self, hashes: Vec<String>, all: bool) -> Result<()> {
        for hash in &hashes {
            for cache in self {
                if let Some(response) = cache.search(&hash)? {
                    ui::show_narinfo(&response);
                    if !all {
                        continue;
                    }
                } else {
                    debug!("{} not found in {}", &hash, &cache)
                }
            }
        }
        Ok(())
    }
}

pub fn parse_substituters(stdout: &str) -> Result<HashSet<NixCache>> {
    for line in stdout.lines() {
        if line.starts_with("substituters =") {
            let caches = line
                .splitn(2, "=")
                .nth(1)
                .ok_or(eyre!("expected = in string"))?
                .split_whitespace()
                .filter(|s| s != &"")
                .map(NixCache::from)
                .collect();
            return Ok(caches);
        }
    }
    bail!("failed to find substituters line in `nix config show` output")
}

pub fn get_substituters() -> Result<HashSet<NixCache>> {
    let stdout = LoggedCommand::new("nix")
        .arg("config")
        .arg("show")
        .stdout_ok()?;
    Ok(parse_substituters(&stdout)?)
}

#[derive(Deserialize, Debug)]
struct NixOutput {
    path: String,
}

#[derive(Deserialize, Debug)]
struct NixInputDrv {
    // dynamicOutputs: ?
    outputs: Vec<String>,
}

#[derive(Deserialize, Debug)]
#[allow(dead_code)]
struct NixDerivation {
    name: String,
    outputs: BTreeMap<String, NixOutput>,
    #[serde(rename = "inputDrvs")]
    input_drvs: BTreeMap<String, NixInputDrv>,
}

type NixDerivationShowOutput = BTreeMap<String, NixDerivation>;

fn get_hash(path: &str) -> Result<String> {
    const HASH_START_INDEX: usize = 11; // The hash always starts after "/nix/store/" which is 11 characters long.
    const HASH_LENGTH: usize = 32; // The hash always has a length of 32 characters.
    let hash_end_index = HASH_START_INDEX + HASH_LENGTH;
    if path.len() >= hash_end_index {
        return Ok(path[HASH_START_INDEX..hash_end_index].into());
    }
    bail!("failed to extract hash from: {}", path)
}

// using nix derivation show for each attr
fn to_hashes(attrs: Vec<String>) -> Result<Vec<String>> {
    let mut hashes = vec![];
    for a in attrs {
        let stdout = NixCommand::default()
            .cmd()
            .arg("derivation")
            .arg("show")
            .arg(a)
            .stdout_ok()?;
        let output: NixDerivationShowOutput = serde_json::from_str(&stdout)?;
        for (_, drv) in output {
            for (_, drv_output) in drv.outputs {
                hashes.push(get_hash(&drv_output.path)?)
            }
        }
    }

    Ok(hashes)
}

pub fn narinfo(attrs: Vec<String>, all: bool) -> Result<()> {
    let hashes = to_hashes(attrs)?;
    let caches = get_substituters()?;
    caches.search(hashes, all)?;
    Ok(())
}

pub fn chezmoi_status() -> Result<()> {
    info!("check chezmoi status");
    let stdout = LoggedCommand::new("chezmoi").arg("status").stdout_ok()?;
    if stdout != "" {
        println!(
            "\nfyi the dotfiles don't match, see below:\n{}:\n{}",
            style("CHEZMOI STATUS").magenta().bold(),
            &crate::indent(stdout)
        )
    }
    Ok(())
}

#[derive(Debug, Eq, Hash, PartialEq)]
enum OizysPackageStatus {
    Local,
    Cached,
}

#[derive(Debug)]
struct OizysPackage {
    name: String,
    drv: String,
    outputs: Vec<String>,
    status: HashSet<OizysPackageStatus>,
}

impl OizysPackage {
    fn from(path: &str, drv: &NixDerivation) -> Self {
        let outputs: Vec<String> = drv.outputs.values().map(|v| v.path.clone()).collect();

        Self {
            name: drv.name.clone(),
            drv: path.into(),
            outputs,
            status: HashSet::new(),
        }
    }

    async fn get_status(&mut self) -> Result<()> {
        if self
            .outputs
            .iter()
            // should maybe be using try_exists actually?
            .all(|p| std::path::Path::new(p).exists())
        {
            self.status.insert(OizysPackageStatus::Local);
        }
        // TODO: now for each of these run a narinfo check (async tho...)
        Ok(())
    }
}

async fn nix_derivation_show(attrs: &Vec<String>) -> Result<NixDerivationShowOutput> {
    println!("showing...");
    let output = tokio::process::Command::new("nix")
        .arg("derivation")
        .arg("show")
        .args(attrs)
        .output()
        .await?;

    if output.status.success() {
        Ok(serde_json::from_str(&String::from_utf8_lossy(
            &output.stdout,
        ))?)
    } else {
        bail!("nix derication show failed for drvs:\n{}", attrs.join("\n"))
    }
}

pub async fn get_oizys_packages(nixos: &Nixos) -> Result<()> {
    let system_drv = nix_derivation_show(&vec![nixos.system_attr().clone()]).await?;
    let inputs: Vec<String> = system_drv.values().map(|v| v.input_drvs.keys().cloned()).flatten().collect();
    let system_input_drvs = nix_derivation_show(&inputs).await?;
    let mut packages: Vec<OizysPackage> = system_input_drvs.iter().map(|(k,v)| OizysPackage::from(k,v)).collect();
    for pkg in &mut packages {
        pkg.get_status().await?
    }

    for package in packages {
        println!("{:?}", package.outputs);
        println!("package = {:?}, {:?}", package.name, package.status);
    }
    Ok(())
}
