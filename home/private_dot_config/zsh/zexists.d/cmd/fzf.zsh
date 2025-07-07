#!/usr/bin/env zsh

# catppuccin
FZF_COLORS="
--color=bg+:#302D41,bg:#1E1E2E,spinner:#F8BD96,hl:#F28FAD
--color=fg:#D9E0EE,header:#F28FAD,info:#DDB6F2,pointer:#F8BD96
--color=marker:#F8BD96,fg+:#F2CDCD,prompt:#DDB6F2,hl+:#F28FAD
"

FZF_LAYOUT="
--height=40%
--margin=0,5,5%
--layout=reverse
"

export FZF_DEFAULT_OPTS=${FZF_COLORS}${FZF_LAYOUT}

zstyle ':fzf-tab:*' fzf-pad 4

#
# old fzf config
#
# export FZF_CTRL_GENERAL="--height=100% --margin=0,0,0"
#
# #adapted from https://github.com/zimfw/fzf/blob/master/init.zsh
# # TODO: fix this so it works with $ **<tab>
# if [ -x "$(command -v fd)" ]; then
# 	export FZF_DEFAULT_COMMAND="command fd --type file --exclude ".git/" --hidden --no-ignore"
# 	_fzf_compgen_path() {
# 		command fd --type file --exclude ".git/" --hidden --no-ignore "${1}"
# 	}
# elif [ -x "$(command -v rg)" ]; then
# 	export FZF_DEFAULT_COMMAND="command rg -uu -g '!.git' --files"
# 	_fzf_compgen_path() {
# 		command rg -uu -g '!.git' --files "${1}"
# 	}
# fi
#
# if [ -x "$(command -v bat)" ]; then
# 	export FZF_CTRL_T_OPTS="
#    --preview 'command bat --style numbers --color=always --line-range :500 {}'
#    --preview-window up,70%,border-rounded
#    ${FZF_CTRL_GENERAL}
#    "
# fi
#
# export FZF_ALT_C_OPTS="
#     --height 60%
#     --preview 'lsd --tree --color always --icon always {}'
#     --preview-window right,60%,border-rounded
#     "
#
# # [[ -v FZF_CTRL_T_COMMAND ]] && && export FZF_CTRL_T_COMMAND=${FZF_DEFAULT_COMMAND}
# [[ -z $FZF_CTRL_T_COMMAND ]] && export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"

# fix spacing on fzf-tab to show max options
