use crate::indent;
use crate::lock::FlakeInput;
use crate::nix::NixPkgEval;
use console::style;
use serde_json::{Value, to_string_pretty};
use std::collections::HashMap;

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
        println!("  {}:{}", style(k).bold(), v)
    }
}

pub fn pretty_value(v: &Value) -> String {
    match v {
        Value::Object(m) => indent(to_string_pretty(&m).unwrap()),
        Value::Array(a) => indent(to_string_pretty(&a).unwrap()),
        other => format!("{}", to_string_pretty(&other).unwrap()),
    }
}

pub fn show_meta(name: &str, pkg: &NixPkgEval, keys: &[String], skip_filter: bool) {
    let print_entry = |k: &str, v: &Value| {
        println!(
            "  {}: {}",
            style(k).bold(),
            pretty_value(v).trim_matches('"')
        );
    };

    println!("{}:", style(name).bold().cyan());
    if skip_filter {
        for (k, v) in pkg {
            print_entry(k, v);
        }
    } else {
        for k in keys {
            match pkg.get(k) {
                Some(v) => print_entry(k, v),
                None => println!("  {}: {}", k, style("UNKNOWN KEY!").red()),
            }
        }
    }
}

pub fn show_duplicates(duplicates: HashMap<String, HashMap<String, FlakeInput>>) {
    println!("{}:", style("DUPLICATED INPUTS").magenta().bold());
    for (dupe, inputs) in duplicates {
        println!(
            "  {}: {}",
            style(dupe).bold(),
            inputs
                .keys()
                .map(|s| s.as_str())
                .collect::<Vec<&str>>()
                .join("; ")
        );
    }
}

pub fn show_non_nulls(non_nulls: HashMap<String, Vec<String>>) {
    println!("{}:", style("NON-NULL INPUTS").magenta().bold());
    for (name, inputs) in non_nulls {
        println!("  {}: {}", style(name).bold(), inputs.join("; "))
    }
}
