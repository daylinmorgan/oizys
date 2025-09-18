use super::prelude::*;
use console::style;
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)] // validate by parsing
struct FlakeInputSource {
    owner: Option<String>,
    repo: Option<String>,
    #[serde(rename = "type")]
    source_type: Option<String>,
    rev: Option<String>,
    #[serde(rename = "narHash")]
    nar_hash: Option<String>,
    #[serde(rename = "ref")]
    reference: Option<String>,
    #[serde(rename = "lastModified")]
    last_modified: Option<i64>,
}

#[derive(Deserialize, Debug, Clone)]
#[serde(untagged)]
#[allow(dead_code)]
enum InputReferences {
    Single(String),
    List(Vec<String>),
}

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)] // validate by parsing
pub struct FlakeInput {
    inputs: Option<HashMap<String, InputReferences>>,
    // inputs: Option<HashMap<String, serde_json::Value>>,
    locked: Option<FlakeInputSource>,
    original: Option<FlakeInputSource>,
}

impl FlakeInput {
    fn has_input(&self, name: &str) -> bool {
        if let Some(inputs) = &self.inputs {
            for (_, input) in inputs {
                match input {
                    InputReferences::Single(input_name) => {
                        if input_name == name {
                            return true;
                        }
                    }
                    InputReferences::List(input_names) => {
                        if input_names.iter().any(|n| n == name) {
                            return true;
                        }
                    }
                }
            }
        }
        false
    }
}

#[derive(Deserialize)]
#[allow(dead_code)] // validate by parsing
pub struct FlakeLock {
    nodes: HashMap<String, FlakeInput>,
    root: String,
    version: i32,
}

impl FlakeLock {
    fn from(s: &str) -> Result<Self> {
        Ok(serde_json::from_str(s)?)
    }

    pub fn from_file(p: PathBuf) -> Result<Self> {
        Self::from(&std::fs::read_to_string(p)?)
    }

    /// matches should return the flake inputs where inputs contains the input
    fn matches(&self, name: &str) -> HashMap<String, FlakeInput> {
        self.nodes
            .iter()
            .filter(|(_, v)| v.has_input(name))
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect()
    }

    pub fn duplicates(&self) -> HashMap<String, HashMap<String, FlakeInput>> {
        let names: Vec<String> = self
            .nodes
            .keys()
            .filter(|n| n.contains("_"))
            .cloned()
            .collect();

        names
            .iter()
            .map(|n| (n.to_string(), self.matches(n)))
            .collect()
    }

}
