#!/usr/bin/env nix-shell
#!nix-shell -p python3 ascii-image-converter figlet -i python3

import argparse
import urllib.request
import subprocess

runes = {
    "algiz": "https://upload.wikimedia.org/wikipedia/commons/1/14/Runic_letter_algiz.png",
    "othalan": "https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png",
    "mannaz": "https://upload.wikimedia.org/wikipedia/commons/0/0c/Runic_letter_mannaz.png",
    "naudiz": "https://upload.wikimedia.org/wikipedia/commons/b/b9/Runic_letter_naudiz.png",
}


def fetch(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
        "Accept-Language": "en-US,en;q=0.9",
    }

    req = urllib.request.Request(url, headers=headers)
    return urllib.request.urlopen(req).read()


def generator(image: bytes, braille: bool = False) -> str:
    cmd = ["ascii-image-converter", "-", "--height", "15", "--negative"]
    if braille:
        cmd.append("--braille")
    return subprocess.run(
        cmd,
        input=image,
        capture_output=True,
    ).stdout.decode()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("rune", help="name of rune")
    parser.add_argument("--braille", help="use braille", action="store_true")
    args = parser.parse_args()
    image = fetch(runes[args.rune])
    print(generator(image, args.braille))


if __name__ == "__main__":
    main()
