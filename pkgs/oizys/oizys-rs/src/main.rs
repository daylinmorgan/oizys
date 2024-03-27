use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::{generate, Generator, Shell};
use std::{env, io, path::PathBuf, process::Command};

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// increase verbosity
    #[arg(short, long,global=true, action = clap::ArgAction::Count)]
    verbose: u8,

    /// path to flake ($OIZYS_DIR or $HOME/oizys)
    #[arg(short, long, global = true)]
    flake: Option<PathBuf>,

    /// host name (current host)
    #[arg(long, global = true)]
    host: Option<String>,

    /// don't use pinix
    #[arg(long, global=true, action = clap::ArgAction::SetTrue)]
    no_pinix: bool,

    /// generate shell completion
    #[arg(long, value_enum)]
    completions: Option<Shell>,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// poor man's nix flake check
    Dry {},

    /// nixos rebuild boot
    Boot {},

    /// nixos rebuild switch
    Switch {},

    /// build and push to cachix
    Cache {
        /// name of cachix binary cache
        #[arg(short, long, default_value = "daylin")]
        name: String,
    },

    ///build nixos (w/ nix build)
    Build {},

    /// print nix flake output
    Path {},
}

fn print_completions<G: Generator>(gen: G, cmd: &mut clap::Command) {
    generate(gen, cmd, cmd.get_name().to_string(), &mut io::stdout());
}

#[derive(Debug)]
struct Oizys {
    host: String,
    flake: PathBuf,
    no_pinix: bool,
    verbose: u8,
}

impl Oizys {
    fn new(host: Option<String>, flake: Option<PathBuf>, no_pinix: bool, verbose: u8) -> Oizys {
        let hostname = hostname::get().unwrap().to_string_lossy().to_string();
        let flake_path = env::var("OIZYS_DIR").map_or(
            homedir::get_my_home().unwrap().unwrap().join("oizys"),
            PathBuf::from,
        );
        Oizys {
            host: host.unwrap_or(hostname),
            flake: flake.unwrap_or(flake_path),
            no_pinix,
            verbose,
        }
    }
    fn output(self: &Oizys) -> String {
        format!(
            "{}#nixosConfigurations.{}.config.system.build.toplevel",
            self.flake.to_string_lossy(),
            self.host
        )
    }

    fn nix(self: &Oizys) -> String {
        (if self.no_pinix { "nix" } else { "pix" }).to_string()
    }

    fn nixos_rebuild_cmd(self: &Oizys) -> String {
        self.nix() + "os-rebuild"
    }
    fn show_cmd(self: &Oizys, cmd: &Command) {
        println!("executing: {}", format!("{:?}", cmd).replace('"', ""));
    }

    fn build(self: &Oizys, dry: bool) {
        let nix = self.nix();
        let flake_output = self.output();
        let mut args = vec!["build", &flake_output.as_str()];
        if dry {
            args.push("--dry-run")
        }
        let mut cmd = Command::new(&nix);
        cmd.args(args);
        if self.verbose >= 2 {
            self.show_cmd(&cmd);
        }
        cmd.status()
            .unwrap_or_else(|_| panic!("failed to run build w/{nix}"));
    }

    fn nixos_rebuild(self: &Oizys, subcommand: &str) {
        let flake_output = format!("{}#{}", self.flake.to_string_lossy(), self.host);
        let mut cmd = Command::new("sudo");
        cmd.args([
            &self.nixos_rebuild_cmd(),
            subcommand,
            "--flake",
            &flake_output,
        ]);
        if self.verbose >= 2 {
            self.show_cmd(&cmd);
        }
        cmd.status()
            .unwrap_or_else(|_| panic!("failed to run nixos-rebuild {subcommand}"));
    }

    fn cache(self: &Oizys, name: &String) {
        let flake_output = self.output();
        let mut cmd = Command::new("cachix");
        cmd.args([
            "watch-exec",
            &name,
            "--",
            "nix",
            "build",
            &flake_output,
            "--print-build-logs",
            "--accept-flake-config",
        ]);
        if self.verbose >= 2 {
            self.show_cmd(&cmd);
        }

        cmd.status()
            .unwrap_or_else(|_| panic!("failed to run cachix watch-exec"));
    }
}

fn main() {
    let cli = Cli::parse();
    let oizys = Oizys::new(cli.host, cli.flake, cli.no_pinix, cli.verbose);

    if let Some(completions) = cli.completions {
        let mut cmd = Cli::command();
        eprintln!("Generating completion for {completions:?}");
        print_completions(completions, &mut cmd);
        std::process::exit(0);
    }

    if oizys.verbose > 2 {
        println!("-vv is max verbosity")
    }
    if oizys.verbose >= 1 {
        println!("{:?}", oizys)
    }

    if let Some(command) = &cli.command {
        match command {
            Commands::Dry {} => oizys.build(true),
            Commands::Build {} => oizys.build(false),
            Commands::Path {} => println!("{}", oizys.output()),
            Commands::Boot {} => oizys.nixos_rebuild("boot"),
            Commands::Switch {} => oizys.nixos_rebuild("switch"),
            Commands::Cache { name } => oizys.cache(name),
        }
    } else {
        eprintln!("No subcommand provided..");
        let mut cmd = Cli::command();
        cmd.print_help().unwrap();
    }
}
