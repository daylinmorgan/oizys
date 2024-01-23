#! /usr/bin/env nix-shell
#! nix-shell -i bash -p ascii-image-converter

set -e
declare -A IMG_SRC
IMG_SRC=(
	[jeran]=https://upload.wikimedia.org/wikipedia/commons/0/01/Runic_letter_jeran.png
	[othalan]=https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png
	[algiz]=https://upload.wikimedia.org/wikipedia/commons/1/14/Runic_letter_algiz.png
	[mannaz]=https://upload.wikimedia.org/wikipedia/commons/0/0c/Runic_letter_mannaz.png
	[kaunan]=https://upload.wikimedia.org/wikipedia/commons/a/a3/Runic_letter_kauna.png
)

if [[ $# -eq 0 ]]; then
	echo please provide rune name
	echo options:
	for i in "${!IMG_SRC[@]}"; do
		echo $i
	done
	exit 1
fi

rune=$1
color=${36:-$2}

# tmp this?
FILENAME="Runic_letter_${rune}.png"

[[ -f "$FILENAME" ]] || wget -O "$FILENAME" "${IMG_SRC[$rune]}"

printf "\033[1;%dm\n%s\033[0m\n\n" \
	"$color" \
	"$(ascii-image-converter "$FILENAME" -n -H 15 -b)" \
	>"${rune}.txt"
