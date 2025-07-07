#!/usr/bin/env bash

if ! [[ -d wez-ref ]]; then
	git clone git@github.com:wez/wezterm.git wez-ref --depth 1
else
	cd wez-ref
	git pull
	cd ..
fi

cat wez-ref/docs/config/lua/keyassignment/* >keys-ref.md
