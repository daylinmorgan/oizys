use crate::process::LoggedCommand;
use serde::Deserialize;
use tracing::{error, info};

#[derive(Deserialize)]
pub struct Substituters {
    #[serde(default)]
    pub substituters: Vec<String>,

    #[serde(default, rename = "trusted-public-keys")]
    pub trusted_public_keys: Vec<String>,
}

const SUBSTITUTERS_JSON: Option<&'static str> = option_env!("OIZYS_SUBSTITUTERS");

pub fn apply_substituter_flags(cmd: &mut LoggedCommand) {
    let Some(json) = SUBSTITUTERS_JSON else {
        error!("build with nix for bootstrap substituters support");
        return;
    };

    match serde_json::from_str::<Substituters>(json) {
        Ok(subs) => {
            info!("including substituters in nix command");
            if !subs.substituters.is_empty() {
                cmd.arg("--substituters");
                cmd.arg(subs.substituters.join(" "));
            }
            if !subs.trusted_public_keys.is_empty() {
                cmd.arg("--trusted-public-keys");
                cmd.arg(subs.trusted_public_keys.join(" "));
            }
        }
        Err(e) => error!("failed to parse substituters json: {e}"),
    }
}
