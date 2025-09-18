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

use super::lock::FlakeInput;
use std::collections::HashMap;

pub fn show_duplicates(duplicates: HashMap<String, HashMap<String, FlakeInput>>) {
    for (dupe, inputs) in duplicates {
        println!(
            "{}: {}",
            style(dupe).bold(),
            inputs
                .keys()
                .map(|s| s.as_str())
                .collect::<Vec<&str>>()
                .join("; ")
        );
    }
}
