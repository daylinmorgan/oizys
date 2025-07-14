#!/usr/bin/env bash

rofi_command="rofi -theme confirm"

options="yes\nno"

chosen="$(echo -e "$options" | $rofi_command -dmenu -selected-row 2)"
echo "$chosen"
