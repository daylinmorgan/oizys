#!/usr/bin/env nix-shell
#!nix-shell -p python3 ascii-image-converter figlet -i python3

from dataclasses import dataclass

@dataclass
class Rune:
    name: str
    url: str

runes = [

# 
# def convert [] {
#   let rune = $in
#   let image = http get $rune.url
#   let flags = [--height 15 --negative]
#   {
#     name: $rune.name
#     braille: ( $image | ascii-image-converter -  --braille ...$flags)
#     ascii: ( $image | ascii-image-converter - ...$flags)
#   }
# }
# 
# def nix-file [] {
#   let rune = $in | convert
#   $"{
# braille = ''($rune.braille)
# '';
# ascii = ''($rune.ascii)
# '';
# }
# " | save -f $"($rune.name).nix"
# }
# 
# def col [] {
#   $in | reduce --fold "" {|it, acc|
#       $acc + $'<td><img src="($it.url)"></td>'
#     }
# }
# 
# def row [] { $"<tr>($in)</tr>" }
# 
# def readme [] {
#   let runes = $in
#   let dims = { rows: 2 cols: 2 }
#   let cells = ($runes | chunks $dims.rows | each { col | row})
#   let table = [ "<table>" ...$cells "</table>" ] | str join
# 
#   $"# Runes\n\n($table)\n"
# }
# 
# $runes
# | readme
# | save -f "README.md"
# 
# $runes
# | each { nix-file }
# 
# 
# const path_to_self = path self | path dirname
# 
# nix fmt $path_to_self
