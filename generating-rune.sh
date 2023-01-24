#!/usr/bin/env bash
set -e
declare -A IMG_SRC
IMG_SRC=(
	[jeran]=https://upload.wikimedia.org/wikipedia/commons/0/01/Runic_letter_jeran.png
	[othalan]=https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png
)


if [[ $# -eq 0 ]]; then
	echo please provide rune name
	echo options:
	for i in "${!IMG_SRC[@]}";do 
		echo $i
	done
	exit 1
fi

rune=$1
echo $2
color=${36:-$2}

# tmp this?
FILENAME="Runic_letter_${rune}.png"

wget -O $FILENAME "${IMG_SRC[$rune]}"
printf "\033[1;%dm\n%s\033[0m \033[1m%s\033[0m\n\n" \
	"$color" \
	"$(ascii-image-converter "$FILENAME" -n -H 10 -b)" \
	"$rune" \
	>"${rune}.txt"
