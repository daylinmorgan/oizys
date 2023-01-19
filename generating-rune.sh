#!/usr/bin/env bash
set -e

# rune=$1
rune=othalan
# color=${36:$2}
# color=${36:$2}
color=36
FILENAME="Runic_letter_${rune}.png"
IMAGE_URL="https://upload.wikimedia.org/wikipedia/commons/1/16/Runic_letter_othalan.png"
echo "$IMAGE_URL"
wget "$IMAGE_URL"
printf "\033[1;%dm\n%s\033[0m \033[1m%s\033[0m\n\n" \
	"$color" \
	"$(ascii-image-converter "$FILENAME" -n -H 18)" \
	"$rune" \
	>"${rune}.txt"
