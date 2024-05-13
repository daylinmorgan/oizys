use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::{generate, Generator, Shell};
use spinoff::{spinners, Color, Spinner};
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

    /// generate shell completion
    #[arg(long, value_enum, hide = true)]
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
    Output {},
}

fn print_completions<G: Generator>(gen: G, cmd: &mut clap::Command) {
    generate(gen, cmd, cmd.get_name().to_string(), &mut io::stdout());
}

#[derive(Debug)]
struct Oizys {
    host: String,
    flake: PathBuf,
    verbose: u8,
}

fn trim_hashes(buf: &str, trim_drv: bool) -> Vec<String> {
    buf.lines()
        .skip(1)
        .map(|line| {
            line.split_once('-')
                .map(|x| {
                    format!("  {}", {
                        if trim_drv {
                            x.1.replace(".drv", "")
                        } else {
                            x.1.to_string()
                        }
                    })
                })
                .expect("failed to trim derivation")
        })
        .collect()
}

impl Oizys {
    fn from(cli: &Cli) -> Oizys {
        let host = cli
            .host
            .clone()
            .unwrap_or(hostname::get().unwrap().to_string_lossy().to_string());
        let flake = cli.flake.clone().unwrap_or(env::var("OIZYS_DIR").map_or(
            homedir::get_my_home().unwrap().unwrap().join("oizys"),
            PathBuf::from,
        ));

        Oizys {
            host,
            flake,
            verbose: cli.verbose,
        }
    }

    fn output(self: &Oizys) -> String {
        format!(
            "{}#nixosConfigurations.{}.config.system.build.toplevel",
            self.flake.to_string_lossy(),
            self.host
        )
    }

    fn show_cmd(self: &Oizys, cmd: &Command) {
        println!("executing: {}", format!("{:?}", cmd).replace('"', ""));
    }

    fn parse_dry_output(self: &Oizys, output: &str) {
        let parts: Vec<&str> = output.split("\nthese").collect();
        // TODO: handle more cases of output
        // currently fails if nothing to fetch
        if parts.len() != 3 {
            eprintln!("couldn't parse dry output into three parts");
            eprintln!("{}", output);
            std::process::exit(1);
        }
        let to_build: Vec<String> = trim_hashes(parts[1], true);
        let to_fetch: Vec<String> = trim_hashes(parts[2], false);
        if self.verbose > 0 {
            println!("TO BUILD: {}\n{}\n", to_build.len(), to_build.join("\n"));
            println!("TO FETCH: {}\n{}\n", to_fetch.len(), to_fetch.join("\n"));
        } else {
            println!("To build: {}", to_build.len());
            println!("To fetch: {}", to_fetch.len());
        }
    }

    fn dry(self: &Oizys) {
        let flake_output = self.output();
        let mut cmd = Command::new("nix");
        cmd.args(["build", &flake_output.as_str(), "--dry-run"]);
        if self.verbose >= 2 {
            self.show_cmd(&cmd)
        }
        let mut spinner = Spinner::new(spinners::Arc, "evaluating...", Color::Cyan);
        let output = String::from_utf8(cmd.output().expect("failed to run nix build").stderr)
            .expect("faild to parse nix build --dry-run output");
        spinner.stop_with_message("evaluating finished");

        if output.contains("derivations will be built") {
            self.parse_dry_output(&output);
        } else {
            println!("{} up to date", self.host)
        }
    }

    fn build(self: &Oizys) {
        let flake_output = self.output();
        let mut cmd = Command::new("nix");
        cmd.args(["build", &flake_output.as_str()]);
        if self.verbose >= 2 {
            self.show_cmd(&cmd);
        }
        cmd.status().expect("failed to run nix build");
    }

    fn nixos_rebuild(self: &Oizys, subcommand: &str) {
        let flake_output = format!("{}#{}", self.flake.to_string_lossy(), self.host);
        let mut cmd = Command::new("sudo");
        cmd.args(["nixos-rebuild", subcommand, "--flake", &flake_output]);
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
    let oizys = Oizys::from(&cli);

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
            Commands::Dry {} => oizys.dry(),
            Commands::Build {} => oizys.build(),
            Commands::Output {} => println!("{}", oizys.output()),
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
