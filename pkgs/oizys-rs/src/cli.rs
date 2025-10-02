use crate::nix::NixName;
use clap::{Parser, Subcommand};
use clap_complete::aot::{generate, Generator, Shell};

#[derive(Debug, clap::Args)]
#[command(next_help_heading = "Global options")]
pub struct GlobalOptions {
    /// verbosity level (up to 4)
    ///
    /// 0: warn
    /// 1: oizys info
    /// 2: oizys debug
    /// 3: all debug
    /// 4: all trace
    /// NOTE: you can use RUST_LOG for more control
    #[arg(short, long, action = clap::ArgAction::Count, global = true, verbatim_doc_comment)]
    pub verbose: u8,

    // TODO: use a PathBuf?
    /// path to flake
    #[arg(short, long, global = true)]
    pub flake: Option<String>,

    /// enable bootstrap mode
    #[arg(long, global = true)]
    pub bootstrap: bool,

    /// binary to use
    #[arg(short, long, global = true, value_enum, default_value_t = NixName::Nom)]
    pub nix: NixName,

    /// hostname
    #[arg(long,global = true, num_args=1.., value_delimiter = ',', default_values_t = [default_host()])]
    pub host: Vec<String>,
}

#[derive(Debug, Parser)]
#[command(
    name = env!("CARGO_PKG_NAME"),
    version = env!("CARGO_PKG_VERSION"),
    about = "nix begat oizys",
    styles = CLAP_STYLING
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,

    #[clap(flatten)]
    pub global: GlobalOptions,
}

#[derive(Debug, Subcommand)]
pub enum Commands {
    #[command(hide = true, name = "self")]
    Current {
        /// nix-args
        #[arg(num_args = 0..)]
        args: Vec<String>,
    },

    /// check oizys package status
    Status {
        /// search caches for outputs
        #[arg(long)]
        check_cache: bool,
    },

    /// nixos config attr
    Output {
        /// show system attr
        #[arg(short, long)]
        system: bool,
    },

    /// nix build
    #[command(visible_alias = "b")]
    Build {
        /// nix-args
        #[arg(num_args = 0..)]
        args: Vec<String>,
    },

    /// nixos-rebuild subcmd
    Os {
        /// subcmd
        cmd: String,

        /// hostname
        #[arg(long, global = true, default_value_t = default_host())]
        host: String,

        /// nix-args
        #[arg(num_args = 0..)]
        args: Vec<String>,
    },

    /// check merge status of nixpkgs PR
    Pr { number: i64 },

    /// trigger GHA workflow
    ///
    /// example:
    ///     oizys gha build --ref main --inputs lockFile=@flake.lock
    Gha {
        /// name of workflow (ext optional)
        workflow: String,

        /// name of git ref
        #[arg(long, name = "ref", default_value_t = ("main").to_string())]
        ref_name: String,

        /// key value pairs for workflow
        ///
        /// separated by '='
        #[arg(short, long, value_parser = parse_key_val::<String, String>)]
        inputs: Vec<(String, String)>,

        /// open workflow run in browser
        #[arg(long)]
        open: bool,
    },

    /// collect build hash from failure
    ///
    /// example:
    ///     oizys hash '.' | wl-copy
    #[command(verbatim_doc_comment)]
    Hash {
        /// nix-args
        args: Vec<String>,
    },

    /// dry run build
    Dry {},

    /// check active caches for nix derivation
    Narinfo {
        #[arg(required = true)]
        attrs: Vec<String>,

        /// search all substituters
        #[arg(short, long)]
        all: bool,
    },

    /// check lock status for duplicates
    ///
    /// I want to lock my flake not yours..
    Lock {
        /// inputs which should be null
        #[arg(long,global = true, num_args=1.., value_delimiter = ',', default_values_t = ["flake-compat".to_string(), "treefmt-nix".to_string()])]
        null: Vec<String>,
    },

    /// generate shell completion
    Completion { shell: Shell },

    /// builtin ci operations
    Ci {
        #[command(subcommand)]
        command: CiCommands,
    },
}

#[derive(Debug, Subcommand)]
pub enum CiCommands {
    /// two stage build of current and updated nixos configurations
    Update,
    /// build and push store paths
    Cache,
}

pub fn default_host() -> String {
    hostname::get().unwrap().into_string().unwrap()
}

pub fn print_completions<G: Generator>(generator: G, cmd: &mut clap::Command) {
    generate(
        generator,
        cmd,
        cmd.get_name().to_string(),
        &mut std::io::stdout(),
    );
}

use std::error::Error;
/// supports parsing arguments as --arg k=v
fn parse_key_val<T, U>(s: &str) -> Result<(T, U), Box<dyn Error + Send + Sync + 'static>>
where
    T: std::str::FromStr,
    T::Err: Error + Send + Sync + 'static,
    U: std::str::FromStr,
    U::Err: Error + Send + Sync + 'static,
{
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid KEY=value: no `=` found in `{s}`"))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}

use clap::builder::styling::{AnsiColor, Style, Styles};
const CLAP_STYLING: Styles = Styles::styled()
    .header(AnsiColor::Magenta.on_default().bold())
    .usage(Style::new().bold())
    .literal(Style::new().bold())
    .placeholder(AnsiColor::Yellow.on_default());
