#!/usr/bin/env bash

rofi_cmd="rofi -theme notes -dmenu -p notes -l 0"

notes "$($rofi_cmd)"
