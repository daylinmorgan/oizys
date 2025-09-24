#![allow(dead_code)] // features are used and result in dead code

use crate::process::LoggedCommand;
use serde::Deserialize;
use tracing::error;
use tracing::info;

#[derive(Deserialize)]
pub struct Substituters {
    #[serde(default)]
    pub substituters: Vec<String>,

    #[serde(default, rename = "trusted-public-keys")]
    pub trusted_public_keys: Vec<String>,
}

#[cfg(feature = "substituters")]
const SUBSTITUTERS_JSON: Option<&'static str> = Some(include_str!("substituters.json"));

#[cfg(not(feature = "substituters"))]
const SUBSTITUTERS_JSON: Option<&'static str> = None;

pub fn parse_substituters() -> Option<Substituters> {
    match serde_json::from_str(SUBSTITUTERS_JSON.unwrap()) {
        Ok(subs) => Some(subs),
        Err(e) => {
            error!("failed to parse substituters json, see error {}", e);
            None
        }
    }
}

pub fn apply_subsituter_flags(cmd: &mut LoggedCommand) {
    if let Some(subs) = parse_substituters() {
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
}
