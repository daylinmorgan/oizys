if (( $+commands[time] )); then
  alias zbench='for i in {1..10}; do time zsh -lic exit; done'
fi

alias zdot='cd ${ZDOTDIR:-~}'
alias dots='cd ${DOTFILES_DIR:-~/oizys}'
alias dots-drop='chezmoi forget --interactive $(chezmoi managed -p absolute | fzf -m)'
# alias dots-add='chezmoi re-add --interactive'

function dots-add {
  chezmoi add $(chezmoi status | grep '^MM' | awk -v home="$HOME/" '{print home$2}' | fzf -m)
}


