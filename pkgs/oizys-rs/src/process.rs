use super::prelude::*;
use color_eyre::{eyre::eyre, Section, SectionExt};
use std::{
    ffi::OsStr,
    os::unix::process::CommandExt,
    process::{Command, ExitStatus, Output},
};
use tracing::debug;

pub struct LoggedCommand {
    command: Command,
}

impl LoggedCommand {
    pub fn new(program: &str) -> Self {
        Self {
            command: Command::new(program),
        }
    }

    pub fn arg<S: AsRef<OsStr>>(&mut self, arg: S) -> &mut Self {
        self.command.arg(arg.as_ref());
        self
    }

    pub fn args<I, S>(&mut self, args: I) -> &mut Self
    where
        I: IntoIterator<Item = S>,
        S: AsRef<OsStr>,
    {
        for arg in args {
            self.arg(arg.as_ref());
        }
        self
    }

    fn debug(&mut self) {
        debug!("Running command: {:?}", self.command);
    }

    fn status(&mut self) -> Result<ExitStatus> {
        self.debug();
        Ok(self.command.status()?)
    }

    // pub fn spawn(&mut self) -> std::io::Result<Child> {
    //     self.debug();
    //     self.command.spawn()
    // }

    pub fn output(&mut self) -> Result<Output> {
        self.debug();
        Ok(self.command.output()?)
    }

    pub fn exec(&mut self) -> std::io::Error {
        self.debug();
        self.command.exec()
    }

    pub fn check_status(&mut self) -> Result<()> {
        let status = self.status()?;
        if !status.success() {
            Err(eyre!("Command failed, but was expected to succeed"))
                .with_section(move || format!("Cmd: {:?}", self.command))
        } else {
            Ok(())
        }
    }
    fn check_output(&mut self, fail: bool) -> Result<(String, String)> {
        let output = self.output()?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        if output.status.success() ^ fail {
            // True if status matches expectation (e.g., success and not fail, or failure and fail)
            Ok((stdout.into(), stderr.into()))
        } else {
            let msg = if output.status.success() {
                "Command succeeded, but was expected to fail"
            } else {
                "Command failed, but was expected to succeed"
            };
            Err(eyre!(msg))
                .with_section(move || format!("Cmd: {:?}", self.command))
                .with_section(move || stdout.trim().to_string().header("Stdout:"))
                .with_section(move || stderr.trim().to_string().header("Stderr:"))
        }
    }

    pub fn stdout_ok(&mut self) -> Result<String> {
        let (stdout, _) = self.check_output(false)?;
        Ok(stdout)
    }
    pub fn stdout_fail(&mut self) -> Result<String> {
        let (stdout, _) = self.check_output(true)?;
        Ok(stdout)
    }
    pub fn stderr_ok(&mut self) -> Result<String> {
        let (_, stderr) = self.check_output(false)?;
        Ok(stderr)
    }
    pub fn stderr_fail(&mut self) -> Result<String> {
        let (_, stderr) = self.check_output(true)?;
        Ok(stderr)
    }
}

