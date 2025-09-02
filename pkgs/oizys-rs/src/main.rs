use anyhow::Result;
use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::aot::{generate, Generator, Shell};
use tracing::{Level};

use oizys::nix::{NixCommand, Nixos, set_flake, NixName};
use oizys::process::LoggedCommand;
use oizys::{check_lock_file, get_hash, github};

#[derive(Debug, Parser)]
#[command(
    name = env!("CARGO_PKG_NAME"),
    version = env!("CARGO_PKG_VERSION"),
    about = "nix begat oizys",
    styles = CLAP_STYLING
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// verbosity level (up to 3)
    #[arg(short, long, action = clap::ArgAction::Count, global = true)]
    verbose: u8,

    // TODO: use a PathBuf?
    /// path to flake
    #[arg(short, long, global = true)]
    flake: Option<String>,

    /// hostname
    #[arg(long, global = true, default_value_t = default_host())]
    host: String,

    /// enable bootstrap mode
    #[arg(long, global = true)]
    bootstrap: bool,

    #[arg(short, long, value_enum, default_value_t = NixName::Pinix)]
    nix: NixName,
}

#[derive(Debug, Subcommand)]
enum Commands {
    #[command(hide = true)]
    Current {
        #[arg(num_args = 0..)]
        args: Vec<String>,
    },

    /// nixos config attr
    Output {
        /// system attr
        #[arg(short, long)]
        system: bool,
    },

    /// nix build
    #[command(visible_alias = "b")]
    Build {
        // TODO: change name
        installables: Vec<String>,
    },

    /// nixos-rebuild subcmd
    Os {
        /// subcmd
        cmd: String,

        /// additional flags passed to nixos-rebuild
        extra_flags: Vec<String>,
    },

    /// check merge status of nixpkgs PR
    Pr { number: i64 },

    /// trigger GHA (WIP)
    Gha {
        /// name of workflow (ext optional)
        workflow: String,

        /// name of git ref
        #[arg(name = "ref", default_value_t = ("main").to_string())]
        ref_name: String,
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

    /// build and push store paths (TDB)
    Cache {},

    /// dry run build (TBD)
    Dry {},

    /// builtin ci (TBD)
    Ci {},

    /// check active caches for nix derivation (TBD)
    Narinfo {},

    /// check lock status for duplicates (TBD)
    Lock {},

    /// generate shell completion
    Completion { shell: Shell },
}

fn default_host() -> String {
    hostname::get().unwrap().into_string().unwrap()
}

fn run_current(flake: &str, args: Vec<String>) {
    let err = LoggedCommand::new("nix")
        .arg("run")
        .arg(format!("{flake}#oizys-rs"))
        .arg("--")
        .args(args)
        .exec();

    // The code below will only be executed if `exec` fails.
    panic!("Unexpected error running oizys-rs current: {err}");
}

fn print_completions<G: Generator>(generator: G, cmd: &mut clap::Command) {
    generate(
        generator,
        cmd,
        cmd.get_name().to_string(),
        &mut std::io::stdout(),
    );
}

fn init_subscriber(cli: &Cli) {
    tracing_subscriber::fmt()
        .without_time()
        .with_writer(std::io::stderr)
        .with_max_level(match cli.verbose {
            0 => Level::ERROR,
            1 => Level::INFO,
            2 => Level::DEBUG,
            _ => Level::TRACE,
        })
        .init();
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    init_subscriber(&cli);

    let nix_command = NixCommand::new(cli.nix, cli.bootstrap);
    let flake = set_flake(cli.flake)?;
    let host = cli.host;

    match cli.command {
        Commands::Current { args } => run_current(&flake, args),
        Commands::Completion { shell } => {
            let mut cmd = Cli::command();
            eprintln!("Generating completion file for {shell}...");
            print_completions(shell, &mut cmd);
        }
        Commands::Build { installables } => {
            let _ = nix_command.build(installables)?;
        }
        Commands::Os { cmd, extra_flags } => {
            Nixos::new(&flake, &host).rebuild(&cmd, extra_flags)?;
        }
        Commands::Output { system } => {
            let nixos = Nixos::new(&flake, &host);
            let attr = if system {
                nixos.system_attr()
            } else {
                nixos.attr()
            };
            println!("{}", attr)
        }
        Commands::Lock {} => println!("{}", check_lock_file(&flake)?),
        Commands::Dry {} => todo!(), // this is really a special case of Build isn't it?
        Commands::Pr { number } => {
            // TOOD: a prettier output for the happy path
            eprintln!("{:?}", github::get_nixpkgs_pr_status(number)?);
        }
        Commands::Gha { workflow, ref_name } => github::oizys_gha_run(&workflow, &ref_name)?,
        Commands::Ci {} => todo!(),
        Commands::Cache {} => todo!(),
        Commands::Hash { args } => {
            print!("{}", get_hash(args)?)
        }
        Commands::Narinfo {} => todo!(),
    }

    Ok(())
}

use clap::builder::styling::{AnsiColor, Styles};
const CLAP_STYLING: Styles = Styles::styled()
    .header(AnsiColor::Magenta.on_default().bold())
    .usage(AnsiColor::Cyan.on_default().bold())
    .literal(AnsiColor::Cyan.on_default().bold())
    .placeholder(AnsiColor::Yellow.on_default());
