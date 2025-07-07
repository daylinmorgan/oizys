#!/usr/bin/env zsh

if (( $+commands[eza] )); then
  export _ZO_FZF_OPTS="--preview 'command eza --tree --icons=always --color=always {2..}'"
fi

# eval "$(zoxide init zsh --cmd cd)"
smartcache eval zoxide init zsh --cmd cd

