use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::aot::{generate, Generator, Shell};
use oizys::{
    github,
    nix::{push_to_attic_cache, run_current, set_flake, NixCommand, NixName, Nixos},
};
use oizys::{nix, prelude::*};

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

    /// verbosity level (up to 4)
    ///
    /// 0: warn
    /// 1: oizys info
    /// 2: oizys debug
    /// 3: all debug
    /// 4: all trace
    /// NOTE: use RUST_LOG for more control
    #[arg(short, long, action = clap::ArgAction::Count, global = true, verbatim_doc_comment)]
    verbose: u8,

    // TODO: use a PathBuf?
    /// path to flake
    #[arg(short, long, global = true)]
    flake: Option<String>,

    /// enable bootstrap mode
    #[arg(long, global = true)]
    bootstrap: bool,

    /// binary to use
    #[arg(short, long, global = true, value_enum, default_value_t = NixName::Nom)]
    nix: NixName,

    /// hostname
    #[arg(long,global = true, num_args=1.., value_delimiter = ',', default_values_t = [default_host()])]
    host: Vec<String>,
}

#[derive(Debug, Subcommand)]
enum Commands {
    #[command(hide = true, name = "self")]
    Current {
        #[arg(num_args = 0..)]
        args: Vec<String>,
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
        // TODO: change name?
        installables: Vec<String>,
    },

    /// nixos-rebuild subcmd
    Os {
        /// subcmd
        cmd: String,

        /// additional flags passed to nixos-rebuild
        extra_flags: Vec<String>,

        /// hostname
        #[arg(long, global = true, default_value_t = default_host())]
        host: String,
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

    /// dry run build (TBD)
    Dry {},

    /// check active caches for nix derivation (TBD)
    Narinfo {},

    /// check lock status for duplicates (TBD)
    Lock {},

    /// generate shell completion
    Completion { shell: Shell },

    /// builtin ci (WIP)
    Ci {
        #[command(subcommand)]
        command: CiCommands,
    },
}

#[derive(Debug, Subcommand)]
enum CiCommands {
    /// build and cache, update nixos configurations (TBD)
    Update,
    /// build and push store paths (WIP)
    Cache,
}

fn default_host() -> String {
    hostname::get().unwrap().into_string().unwrap()
}

fn print_completions<G: Generator>(generator: G, cmd: &mut clap::Command) {
    generate(
        generator,
        cmd,
        cmd.get_name().to_string(),
        &mut std::io::stdout(),
    );
}

fn main() -> Result<()> {
    color_eyre::install()?;

    let cli = Cli::parse();

    oizys::init_subscriber(cli.verbose);

    let nix = NixCommand::new(&cli.nix, cli.bootstrap);
    let flake = set_flake(cli.flake)?;
    let hosts = cli.host;

    match cli.command {
        Commands::Current { args } => run_current(&nix, &flake, args),
        Commands::Completion { shell } => {
            let mut cmd = Cli::command();
            eprintln!("Generating completion file for {shell}...");
            print_completions(shell, &mut cmd);
        }
        Commands::Build { installables } => {
            let _ = nix.build(installables)?;
        }
        Commands::Os {
            cmd,
            host,
            extra_flags,
        } => {
            // only one...
            Nixos::new(&flake, &host).rebuild(cli.nix, &cmd, extra_flags)?;
        }
        Commands::Output { system } => {
            for host in hosts {
                let nixos = Nixos::new(&flake, &host);
                let attr = if system {
                    nixos.system_attr()
                } else {
                    nixos.attr()
                };
                print!("{} ", attr);
            }
            print!("\n")
        }
        Commands::Lock {} => oizys::check_lock_file(&flake)?,
        Commands::Dry {} => {
            let attrs = hosts
                .iter()
                .map(|h| Nixos::new(&flake, &h).system_attr())
                .collect();

            let drvs = nix.not_cached(&attrs)?;
            if drvs.is_empty() {
                println!("nothing to build :)")
            } else {
                ui::show_drvs(drvs);
            }
        }
        Commands::Pr { number } => {
            let status = github::get_nixpkgs_pr_status(number)?;
            println!("PR {}", style(format!("{number}")).bold());
            println!("{}", status)
        }

        Commands::Gha {
            workflow,
            ref_name,
            inputs,
        } => {
            let run_id = github::oizys_gha_run(&workflow, &ref_name, inputs)?;
            println!(
                "view workflow run at: https://github.com/daylinmorgan/oizys/actions/runs/{}",
                run_id
            );
        }
        Commands::Ci { command } => {
            match command {
                CiCommands::Update => todo!(),
                CiCommands::Cache => {
                    // current implementation is the naive implementation
                    // future versions may rely on nix-eval-jobs

                    let drvs = nix::get_not_cached_nix_eval_jobs(&flake, &hosts)?;
                    if !drvs.is_empty() {
                        let results = nix.build_drvs_multi(&drvs)?;
                        push_to_attic_cache(results, "oizys")?;
                    }
                }
            }
        }
        Commands::Hash { args } => {
            print!("{}", oizys::get_hash(args)?)
        }
        Commands::Narinfo {} => todo!(),
    }

    Ok(())
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

use clap::builder::styling::{AnsiColor, Styles};
const CLAP_STYLING: Styles = Styles::styled()
    .header(AnsiColor::Magenta.on_default().bold())
    .usage(AnsiColor::Cyan.on_default().bold())
    .literal(AnsiColor::Cyan.on_default().bold())
    .placeholder(AnsiColor::Yellow.on_default());
