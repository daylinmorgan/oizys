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

    pub fn status(&mut self) -> std::io::Result<ExitStatus> {
        self.debug();
        self.command.status()
    }

    // pub fn spawn(&mut self) -> std::io::Result<Child> {
    //     self.debug();
    //     self.command.spawn()
    // }

    pub fn output(&mut self) -> std::io::Result<Output> {
        self.debug();
        self.command.output()
    }
    pub fn exec(&mut self) -> std::io::Error {
        self.debug();
        self.command.exec()
    }
}
