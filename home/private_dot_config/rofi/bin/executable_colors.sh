#!/usr/bin/env bash

COLORSCRIPT="$HOME/.config/qtile/colors.py"

rofi -show color -modes "color:$COLORSCRIPT" -theme launcher
