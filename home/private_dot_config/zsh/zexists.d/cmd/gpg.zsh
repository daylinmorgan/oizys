#!/usr/bin/env zsh

export GPG_TTY="$TTY"
gpgconf --launch gpg-agent

# have gpg-agent be the ssh-agent
# idea taken from https://wiki.archlinux.org/title/GnuPG#SSH_agent
if [[ -z "${SSH_CONNECTION}" ]]; then
    export SSH_AGENT_PID=""
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
fi
