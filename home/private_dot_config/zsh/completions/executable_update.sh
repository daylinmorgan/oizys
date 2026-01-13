#!/usr/bin/env zsh

CURDIR=${0:a:h}

is-exe () {
	[ -x "$(command -v $1)" ] && return 0 || return 1
}

gen() {
	if is-exe "$1"; then
		"$@" | sed "s#$HOME#\$HOME#g" >$CURDIR/"_$argv[1]"
		echo "$1 updated"
	else
		echo "skipping $1"
	fi
}

echo "GENERATING COMPLETION SCRIPTS"
echo "-----------------------------"

gen pdm completion zsh
gen chezmoi completion zsh
gen rye self completion -s zsh
gen gh completion -s zsh
gen pixi completion -s zsh
gen rclone completion zsh -

# jj is "special"

if is-exe "jj"; then
  COMPLETE=zsh jj > _jj
fi

