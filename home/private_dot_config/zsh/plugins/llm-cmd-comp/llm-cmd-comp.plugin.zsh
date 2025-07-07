# Bind Ctrl+Q to LLM command completion (generation)
stty -ixon # disables 'flow control' mechanism so I can use ctrl+q
bindkey '^Q' __llm_cmdcomp

# TODO: don't show "Aborted." do I need to intercept ctrl+c somehow?

__llm_cmdcomp() {
  local old_cmd=$BUFFER
  local cursor_pos=$CURSOR
  echo # Start the program on a blank line
  local result=$(llm cmdcomp "$old_cmd")
  if [ $? -eq 0 ] && [ ! -z "$result" ]; then
    BUFFER=$result
  else
    BUFFER=$old_cmd
  fi
  zle reset-prompt
}

zle -N __llm_cmdcomp

