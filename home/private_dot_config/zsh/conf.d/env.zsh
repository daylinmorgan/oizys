#!/usr/bin/env zsh

# export PYTHONPATH="$PYTHONPATH:$(viv m s -p)"
export PYTHONPATH="$PYTHONPATH:$HOME/.local/share/viv"
export VIV_NO_SETUPTOOLS=1
export VIV_RUN_MODE='semi-ephemeral'

export TSM_CONFIG="$XDG_CONFIG_HOME/tsm/config-$(hostname).usu"

export MAGIC_ENTER_GIT_COMMAND="$MAGIC_ENTER_OTHER_COMMAND && git status -sb"
export MAGIC_ENTER_OTHER_COMMAND="ls -l ."

# https://github.com/dandavison/delta/issues/1616
# https://github.com/ryanoasis/nerd-fonts/issues/1337
# make less display nerd-font code points
# export LESSUTFCHARDEF='E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p'
export LESSUTFCHARDEF='23fb-23fe:w,2665:w,2b58:w,e000-e00a:w,e0a0-e0a3:p,e0b0-e0bf:p,e0c0-e0c8:w,e0ca:w,e0cc-e0d7:w,e200-e2a9:w,e300-e3e3:w,e5fa-e6b5:w,e700-e7c5:w,ea60-ec1e:w,ed00-efce:w,f000-f2ff:w,f300-f375:w,f400-f533:w,f0001-f1af0:w'

export FENFMT_PY_FORMATTER="ruff format"
export FENFMT_PYTHON_FORMATTER="ruff format"

