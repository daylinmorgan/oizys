use clap::{CommandFactory, Parser};
use oizys::prelude::*;
use oizys::{
    cli::{self, CiCommands, Cli, Commands},
    github,
    nix::{self, NixCommand, Nixos, NixosOps},
    process::LoggedCommand,
};

#[tokio::main]
async fn main() -> Result<()> {
    color_eyre::install()?;

    let cli = cli::Cli::parse();

    oizys::init_subscriber(cli.global.verbose);

    let nix = NixCommand::new(&cli.global.nix, cli.global.bootstrap);
    let flake = nix::set_flake(cli.global.flake)?;
    let hosts = cli.global.host;
    let systems = Nixos::new_multi(&flake, &hosts);

    match cli.command {
        Commands::Status {check_cache } => {
            for nixos in &systems {
                println!("{:?}", nixos);
                nix::get_oizys_packages(&nixos, check_cache).await?;
            }
        }

        Commands::Current { args } => nix::run_current(&nix, &flake, args),
        Commands::Completion { shell } => {
            let mut cmd = Cli::command();
            eprintln!("Generating completion file for {shell}...");
            cli::print_completions(shell, &mut cmd);
        }
        Commands::Build { args } => {
            nix.build(args)?;
        }
        Commands::Os { cmd, host, args } => {
            Nixos::new(&flake, &host).rebuild(cli.global.nix, &cmd, args)?;
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
        Commands::Lock { null } => {
            oizys::check_lock_file(&flake, null)?;
        }
        // todo: account for packages that will be fetched too
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
            open,
        } => {
            let run_id = github::oizys_gha_run(&workflow, &ref_name, inputs)?;
            let url = format!(
                "https://github.com/daylinmorgan/oizys/actions/runs/{}",
                run_id
            );
            println!("view workflow run at: {}", url);
            if open {
                LoggedCommand::new("xdg-open").arg(url).check_status()?
            }
        }
        Commands::Ci { command } => match command {
            CiCommands::Update => systems.build_update_build()?,
            CiCommands::Cache => {
                let drvs = systems.not_cached()?;
                if !drvs.is_empty() {
                    let to_push = nix.build_drvs_multi(drvs).await?;
                    if !to_push.is_empty() {
                        nix::AtticCache::new("oizys").push(to_push)?;
                    } else {
                        eprintln!("nothing to push :)")
                    }
                } else {
                    eprintln!("no derivations to build :)")
                }
            }
        },
        Commands::Hash { args } => {
            print!("{}", oizys::get_hash(args)?)
        }
        Commands::Narinfo { attrs, all } => oizys::nix::narinfo(attrs, all)?,
    }

    Ok(())
}
