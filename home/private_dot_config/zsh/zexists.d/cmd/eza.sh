#!/usr/bin/env zsh

export EZA_COLORS="da=37"
export EZA_MIN_LUMINANCE=50

alias eza="eza --group-directories-first"
is-tty || alias eza="${aliases[eza]:-eza} --icons"

alias ls='eza'
alias la='eza -la'
alias l='eza -lb'
# alias llm='eza -lbGd --git --sort=modified'
alias lx='eza --long --binary --header --links --group --created --modified --accessed --blocksize --all --time-style=long-iso --git --color-scale'

alias lS='eza -1'
alias lt='eza --tree --level=2'
alias l.="eza -a | grep -E '^\.'"

