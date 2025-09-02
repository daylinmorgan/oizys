pub mod github;
pub mod nix;
pub mod process;
pub mod substituters;

use anyhow::{bail, Result};
use process::LoggedCommand;

fn get_hash_from_output(output: &str) -> Result<String> {
    let re = regex::Regex::new(r"(?m)^\s+got:\s+(?<hash>.*)$").unwrap();
    let Some(caps) = re.captures(output) else {
        bail!("no hash found");
    };

    Ok(caps["hash"].to_string())
}

pub fn get_hash(args: Vec<String>) -> Result<String> {
    let output = LoggedCommand::new("nix").arg("build").args(args).output()?;

    if output.status.success() {
        bail!(
            "expected nix build failure, did you set the hash to \"\", see below for output:\n{:?}",
            &output
        );
    }

    let stderr = String::from_utf8(output.stderr)?;

    Ok(get_hash_from_output(&stderr)?)
}

pub fn indent(s: String) -> String {
    let mut indented = String::new();
    for l in s.lines() {
        indented.push_str("  ");
        indented.push_str(l)
    }
    return indented;
}


pub fn check_lock_file(flake: &str) -> Result<String> {
    let lock_file = std::path::PathBuf::from(flake).join("flake.lock");

    // let json: serde_json::Value = serde_json::from_str(&std::fs::read_to_string(&lock_file)?)?;

    // TODO: drop jq dependency
    if !which::which("jq").is_ok() {
        bail!("jq not found, but required for `oizys lock`")
    }
    let output = LoggedCommand::new("jq")
        .arg(".nodes | keys[] | select(contains(\"_\"))")
        .arg("-r")
        .arg(lock_file)
        .output()?;

    if !output.status.success() {
        bail!("jq failed unexpecetedly: {:?}", output);
    }

    Ok(String::from_utf8(output.stdout)?.trim_end().to_string())

    // newCommand("jq").withArgs(".nodes | keys[] | select(contains(\"_\"))", "-r", lockFile).runQuit()
}

// let lockfile = getFlake() / "flake.lock"
