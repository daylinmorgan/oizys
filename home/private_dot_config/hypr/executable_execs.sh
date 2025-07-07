#!/usr/bin/env bash

# exec-once = hyprctl setcursor catppuccin-mocha-dark-cursors 24
# exec-once = swww-daemon
# exec-once = mako
# exec-once = udiskie
# exec-once = xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
# exec-once = ~/wallpapers/cycle.sh
#
pkill hypridle
hypridle &

pkill kanshi
kanshi &

kill $(pgrep --full 'hyprman watch')

hyprman watch & # start eww here?

pkill eww # started by hyprman start
hyprman start &
