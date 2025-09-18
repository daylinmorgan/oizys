pub mod github;
pub mod lock;
pub mod nix;
pub mod process;
pub mod substituters;
pub mod ui;

use indicatif::ProgressStyle;
use prelude::*;
use process::LoggedCommand;
use std::path::PathBuf;

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
        indented.push_str("\n");
    }
    return indented;
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

#[deprecated]
pub fn check_lock_file_jq(lock_file: PathBuf) -> Result<()> {
    if !which::which("jq").is_ok() {
        bail!("jq not found, but required for `oizys lock`")
    }

    let stdout = LoggedCommand::new("jq")
        .arg(".nodes | keys[] | select(contains(\"_\"))")
        .arg("-r")
        .arg(lock_file)
        .stdout_ok()?;

    if stdout != "" {
        println!("{}", stdout);
    } else {
        eprintln!("nothing to change :)");
    }
    Ok(())
}

fn default_progress_style() -> ProgressStyle {
    ProgressStyle::with_template("{span_child_prefix}{spinner:.magenta} {span_name} {span_fields}")
        .unwrap()
        .tick_strings(&["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"])
}

pub fn init_subscriber(verbose: u8) {
    use tracing_subscriber::prelude::*;
    use tracing_subscriber::{fmt, EnvFilter};

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
    pub use color_eyre::eyre::{bail, eyre, WrapErr};
    pub use color_eyre::Result;
    pub use console::style;
}
