#!/usr/bin/env nix-shell
#!nix-shell -p nushell ascii-image-converter -i nu


let runes = [
  {name: "algiz"   url: "https://upload.wikimedia.org/wikipedia/commons/1/14/Runic_letter_algiz.png"   },
  {name: "othalan" url: "https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png" },
  {name: "mannaz"  url: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Runic_letter_mannaz.png"  },
  {name: "naudiz"  url: "https://upload.wikimedia.org/wikipedia/commons/b/b9/Runic_letter_naudiz.png"  },
]

def convert [] {
  let rune = $in
  let image = http get $rune.url
  let flags = [--height 15 --negative]
  {
    name: $rune.name
    braille: ( $image | ascii-image-converter -  --braille ...$flags)
    ascii: ( $image | ascii-image-converter - ...$flags)
  }
}

def nix-file [] {
  let rune = $in | convert
  $"{
braille = ''($rune.braille)
'';
ascii = ''($rune.ascii)
'';
}
" | save -f $"($rune.name).nix"
}

def col [] {
  $in | reduce --fold "" {|it, acc|
      $acc + $'<td><img src="($it.url)"></td>'
    }
}

def row [] { $"<tr>($in)</tr>" }

def readme [] {
  let runes = $in
  let dims = { rows: 2 cols: 2 }
  let cells = ($runes | chunks $dims.rows | each { col | row})
  let table = [ "<table>" ...$cells "</table>" ] | str join

  $"# Runes\n\n($table)\n"
}

$runes
| readme
| save -f "README.md"

$runes
| each { nix-file }


nix fmt
