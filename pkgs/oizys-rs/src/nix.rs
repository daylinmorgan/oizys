use super::process::LoggedCommand;
use anyhow::{bail, Context, Result};
use clap::ValueEnum;
use std::process::ExitStatus;
use tracing::info;

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
pub struct NixCommand {
    bin: String,
    bootstrap: bool,
}

impl NixCommand {
    fn choose(name: NixName) -> String {
        let bin = name.to_string();
        match name {
            NixName::Nix => bin,
            _ => match which::which(&bin) {
                Ok(_) => bin,
                Err(_) => {
                    info!("{bin} not found falling back to nix");
                    "nix".to_string()
                }
            },
        }
    }

    pub fn new(name: NixName, bootstrap: bool) -> Self {
        Self {
            bin: if !bootstrap {
                Self::choose(name)
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

    pub fn build(&self, installables: Vec<String>) -> Result<ExitStatus> {
        let mut cmd = self.cmd();
        cmd.arg("build").args(installables);
        cmd.status().with_context(|| "nix build failed")
    }
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

    pub fn rebuild(&self, subcmd: &str, extra_flags: Vec<String>) -> Result<()> {
        let attr = format!("{}#{}", self.flake, self.host);

        LoggedCommand::new("sudo")
            .arg("nixos-rebuild")
            .arg(subcmd)
            .arg("--flake")
            .arg(attr)
            .args(extra_flags)
            .status()
            .with_context(|| "nixos-rebuild failed")?;

        if subcmd == "switch" {
            info!("check chezmoi status");
            let output = LoggedCommand::new("chezmoi").arg("status").output()?;
            if !output.status.success() {
                bail!("chezmoi status failed");
            }

            if output.stdout.is_empty() {
                return Ok(());
            }
            let stdout = String::from_utf8(output.stdout)?;

            println!(
                "fyi the dotfiles don't match, see below:\n{}",
                &super::indent(stdout)
            )
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
