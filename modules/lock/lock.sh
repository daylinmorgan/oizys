#!/usr/bin/env bash

# colors
bg_color=1e1e2ebb
red=f38ba8ff
teal=94e2d5ff
rosewater=f5e0dcff
green=a6e3a1ff
selection=454158ff

# greeter config
font="MonoLisa Nerd Font:style=Bold"
greeter_msg="LOCKED"

ff=(
	"big"
	"small"
	"lean"
	"epic"
	"fender"
	"slant"
	"lineblocks"
	"marquee"
	"avatar"
	"contrast"
	"amcrazor"
	"kban"
)

fig_font=${ff[RANDOM % ${#ff[@]}]}

make_figlet() {
	figlet -f "$fig_font" "$greeter_msg"
}

font_size=25
font_to_px=$((font_size * 16 / 12))
greeter_h=$(($(make_figlet | wc -l) * font_to_px))
greeter_w=$(($(make_figlet | wc -L) * font_to_px))

# centered 
greeter_pos="x+w/2-${greeter_w}/4:y+h/2-${greeter_h}/4"
# left-aligned
greeter_pos="x+50:y+h/2-${greeter_h}/4"

# do the locking

# suspend message display
pkill -u "$USER" -USR1 dunst
sleep 0.1

# lock the screen
i3lock \
	-n \
	--screen 1 \
	--color $bg_color \
	--inside-color ffffff00 \
	--ring-color $green \
	--ringwrong-color $red \
	--ringver-color $teal \
	--insidewrong-color $bg_color \
	--insidever-color $bg_color \
	--line-uses-ring \
	--separator-color $selection \
	--keyhl-color $teal \
	--bshl-color $red \
	--wrong-color $red \
	--ind-pos x+w-5-r:y+h-10-r \
	--ring-width 25 \
	--radius 100 \
	--verif-text "" \
	--greeter-text "$(make_figlet)" \
	--greeter-font "${font}" \
	--greeter-size $font_size \
	--greeter-color $rosewater \
	--greeter-pos "${greeter_pos}" \
	--greeter-align 1

# resume message display
pkill -u "$USER" -USR2 dunst
