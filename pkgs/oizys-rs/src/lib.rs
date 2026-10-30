pub mod cli;
pub mod github;
pub mod lock;
pub mod nix;
pub mod process;
pub mod substituters;
pub mod ui;

use indicatif::ProgressStyle;
use prelude::*;
use process::LoggedCommand;
use serde::Deserialize;
use std::collections::HashMap;
use std::io::Write;
use std::path::PathBuf;
use std::process::{Command, Stdio};

// shouldn't this be an option?
fn get_hash_from_output(output: &str) -> Option<String> {
    regex::Regex::new(r"(?m)^\s+got:\s+(?<hash>.*)$")
        .unwrap()
        .captures(output)
        .map(|caps| caps["hash"].into())
}

pub fn get_hash(args: Vec<String>) -> Result<String> {
    let stderr = LoggedCommand::new("nix")
        .arg("build")
        .args(args)
        .stderr_fail()?;

    get_hash_from_output(&stderr).ok_or(eyre!("failed to extract hash from output"))
}

pub fn indent(s: String) -> String {
    let mut indented = String::new();
    for l in s.lines() {
        indented.push_str("  ");
        indented.push_str(l);
        indented.push('\n');
    }
    indented
}

pub fn copy_to_clipboard(data: String) -> Result<()> {
    tracing::debug!("copying data to clipboard");
    let mut cmd = Command::new("wl-copy")
        .stdin(Stdio::piped())
        .spawn()
        .wrap_err("failed to start wl-copy")?;

    if let Some(mut stdin) = cmd.stdin.take() {
        stdin.write_all(&data.into_bytes())?;
        drop(stdin);
    }

    cmd.wait()?;
    eprintln!("data copied to clipboard!");

    Ok(())
}

pub fn check_lock_file(flake: &str, null: Vec<String>) -> Result<()> {
    let flake_lock = lock::FlakeLock::from_file(PathBuf::from(flake).join("flake.lock"))?;
    let duplicates = flake_lock.duplicates();
    if duplicates.is_empty() {
        eprintln!("No duplicated inputs!")
    } else {
        ui::show_duplicates(duplicates);
    }

    let non_nulls = flake_lock.check_null(null);
    if non_nulls.is_empty() {
        eprintln!("No \"non-null\" null inputs")
    } else {
        ui::show_non_nulls(non_nulls);
    }
    Ok(())
}

pub fn possible_hosts() -> Vec<String> {
    let hosts_str = option_env!("OIZYS_HOSTS").unwrap_or("othalan");
    let mut hosts: Vec<String> = hosts_str.split(",").map(|s| s.to_string()).collect();
    if std::env::var_os("NIX_BUILD_TOP").is_some() {
        tracing::info!("add localhost since in build environment");
        hosts.push("localhost".into());
    }
    hosts
}


type OverlayPrs = HashMap<String, HashMap<String, u64>>;

#[derive(Debug, Deserialize)]
struct OizysData {
    #[serde(rename="nixpkgs-overlays")]
    nixpkgs_overlays: OverlayPrs,
}

pub fn get_lib_overlay_prs(flake: &str) -> Result<OverlayPrs> {
    let data_file = format!("{flake}/lib/data.nix");
    let exists = std::path::Path::new(&data_file).try_exists()?;
    if !exists {
        bail!("lib/data.nix is not a file, are you using a local oizys?")
    }
    let data_str = nix::NixCommand::default()
        .nix()
        .args(["eval", "-f", &data_file, "--json"])
        .stdout_ok()?;
    let data: OizysData = serde_json::from_str(&data_str)?;
    Ok(data.nixpkgs_overlays)
}


fn default_progress_style() -> ProgressStyle {
    ProgressStyle::with_template("{span_child_prefix}{spinner:.magenta} {span_name} {span_fields}")
        .unwrap()
        .tick_strings(&["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"])
}

pub fn init_subscriber(verbose: u8) {
    use tracing_subscriber::prelude::*;
    use tracing_subscriber::{EnvFilter, fmt};

    let indicatif_layer =
        tracing_indicatif::IndicatifLayer::new().with_progress_style(default_progress_style());
    let filter_layer = EnvFilter::try_from_default_env()
        .or_else(|_| match verbose {
            0 => EnvFilter::try_new("warn,oizys::progress=trace"),
            1 => EnvFilter::try_new("warn,oizys=info"),
            2 => EnvFilter::try_new("warn,oizys=debug"),
            3 => EnvFilter::try_new("debug"),
            _ => EnvFilter::try_new("trace"),
        })
        .unwrap();

    // let tree_layer = tracing_tree::HierarchicalLayer::new(2)
    //     .with_writer(indicatif_layer.get_stderr_writer())
    //     // .with_indent_lines(true)
    //     .with_targets(true)
    //     .with_span_style(nu_ansi_term::Style::new().bold());

    let fmt_layer = fmt::layer()
        .without_time()
        .with_writer(indicatif_layer.get_stderr_writer());
    tracing_subscriber::registry()
        .with(fmt_layer)
        // .with(tree_layer)
        .with(filter_layer)
        .with(indicatif_layer)
        .init();

    tracing::debug!("run with -vvv to see third-party log messages");
}

#[macro_export]
macro_rules! bar_span {
    ($name:literal) => {
        tracing::info_span!(target: "oizys::progress", $name)
    };
}

pub mod prelude {
    pub static APP_USER_AGENT: &str =
        concat!(env!("CARGO_PKG_NAME"), "/", env!("CARGO_PKG_VERSION"));
    pub use crate::ui;
    pub use bar_span;
    pub use color_eyre::Result;
    pub use color_eyre::eyre::{WrapErr, bail, ensure, eyre};
    pub use console::style;
}
