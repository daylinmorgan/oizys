#!/usr/bin/env bash

styles="$(dirname "$(which $0)")/../styles"
rofi_cmd="rofi -theme $styles/notes.rasi -dmenu -p notes -l 0"

notes "$($rofi_cmd)"
