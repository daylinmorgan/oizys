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

    let nix = NixCommand::new(false, cli.global.bootstrap);

    let flake = nix::set_flake(cli.global.flake)?;
    let hosts = cli.global.host;
    let systems: Vec<Nixos> = Nixos::new_multi(&nix, &flake, &hosts);

    match cli.command {
        Commands::Current { args } => nix::run_current(&nix, &flake, args)?,
        Commands::Completion { shell } => {
            let mut cmd = Cli::command();
            eprintln!("Generating completion file for {shell}...");
            cli::print_completions(shell, &mut cmd);
        }
        Commands::Build { args, build } => {
            let nix = NixCommand::new(build.no_nom, cli.global.bootstrap);
            nix.build(args)?;
        }
        Commands::Os { cmd, host, args } => {
            Nixos::new(&nix, &flake, &host).rebuild(&cmd, args)?;
        }
        Commands::Attr { system, lix } => {
            let mut attrs = vec![];
            for nixos in systems {
                if lix {
                    let lix_attrs = nixos.lix_and_co()?;
                    attrs.extend_from_slice(&lix_attrs);
                }
                if system {
                    attrs.push(nixos.system_attr())
                }
                if !system && !lix {
                    attrs.push(nixos.attr());
                }
            }
            println!("{}", attrs.join("\n"));
        }
        Commands::Lock { null } => {
            oizys::check_lock_file(&flake, null)?;
        }

        // todo: account for packages that will be fetched too
        Commands::Dry {} => {
            let attrs: Vec<String> = systems.into_iter().map(|s| s.system_attr()).collect();
            let drvs = nix.not_cached(&attrs)?;
            if drvs.is_empty() {
                println!("nothing to build :)")
            } else {
                ui::show_drvs(drvs);
            }
        }
        Commands::Pr { numbers ,ignore_data} => {
            // TODO: add support for reading from lib/data.nix
            if !ignore_data {

            let overlay_prs = oizys::get_lib_overlay_prs(&flake)?;
            for (branch, prs) in overlay_prs {
                println!("flake input {}",  style(branch).bold());
                for (name, num) in prs {
                    let status = github::get_nixpkgs_pr_status(num).await?;
                    println!("package {}", style(name).bold());
                    println!("PR {}", style(format!("{num}")).bold());
                    println!("{}", status)
                }
            }

            }
            for num in numbers {
                let status = github::get_nixpkgs_pr_status(num).await?;
                println!("PR {}", style(format!("{num}")).bold());
                println!("{}", status)
            }
        }

        Commands::Gha {
            workflow,
            ref_name,
            inputs,
            open,
        } => {
            let run_id = github::oizys_gha_run(&workflow, &ref_name, inputs).await?;
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
            CiCommands::Update { args } => systems.build_update_build(args)?,
            CiCommands::Cache { args } => {
                let drvs = systems.not_cached()?;
                if !drvs.is_empty() {
                    let (to_push, missing) = nix.build_drvs_multi(drvs, args)?;

                    if !to_push.is_empty() {
                        nix::CellerCache::new("oizys").push(to_push)?;
                    } else {
                        eprintln!("nothing to push :)")
                    }
                    if !missing.is_empty() {
                        bail!("not all derivations built successfully")
                    }
                } else {
                    eprintln!("no derivations to build :)")
                }
            }
        },
        Commands::Hash { args } => {
            // TODO: add clipboard coping via wl-paste
            let hash = oizys::get_hash(args)?;
            oizys::copy_to_clipboard(hash.clone())?;
            // LoggedCommand::new("wl-paste") // how to input?
            print!("{}", hash);
        }
        Commands::Narinfo { attrs, all } => oizys::nix::narinfo(attrs, all).await?,
    }

    Ok(())
}
