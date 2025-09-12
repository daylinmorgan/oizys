use console::style;
pub fn show_drvs(drvs: Vec<String>) {
    println!("{} derivation(s) to build:", drvs.len());
    let drvs = drvs.iter().map(|d| {
        d.strip_suffix(".drv")
            .unwrap()
            .strip_prefix("/nix/store/")
            .unwrap()
            .split_once("-")
            .unwrap()
    });
    for (hash, name) in drvs {
        println!("  {} {}", style(hash).dim(), style(name).bold());
    }
}
