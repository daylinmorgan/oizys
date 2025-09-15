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

pub fn show_narinfo(info: &str) {
    println!("{}", style("NARINFO").bold().cyan());
    for line in info.lines() {
        let split: Vec<&str> = line.splitn(2, ":").collect();
        let (k, v) = (split[0], split[1]); // could panic ¯\_(ツ)_/¯
        print!("  {}:{}\n", style(k).bold(), v)
    }
}
