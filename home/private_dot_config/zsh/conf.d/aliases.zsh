alias g=git
alias c=clear

alias vi=vim

alias rr="rm -rf"

# # more ways to ls
# alias ls="${aliases[ls]:-ls} --group-directories-first --color=auto -I 'System Volume Information'"
# alias l='ls -lh'
# alias la='ls -a'
# alias ldot='ls -ld .*'
# alias lr='ls -R'
# alias lsl="ls -lhFA --color=always | less"
# alias left='ls -t -1'
#
# GNU make
alias mkrt='make -C $(git rev-parse --show-toplevel)'
alias mk="make"
alias mkc="make -C"

# alias yyyymmdd='date +%Y%m%d'
# alias ds='date +%Y-%m-%d'
alias timestamp='date +%Y-%m-%dT%H:%M:%SZ'

# url encode/decode
alias urldecode='python3 -c "import sys, urllib.parse as ul; \
    print(ul.unquote_plus(sys.argv[1]))"'
alias urlencode='python3 -c "import sys, urllib.parse as ul; \
    print (ul.quote_plus(sys.argv[1]))"'

alias rclone='rclone --filter-from ~/.config/rclone/filter-file.txt'

alias viv-remote='python3 <(curl -fsSL viv.dayl.in/viv.py)'
alias viv-dev='python3 <(curl -fsSL https://raw.githubusercontent.com/daylinmorgan/viv/dev/src/viv/viv.py)'

# increment a build number and maintain Lexicographic order
alias lexid-inc="python -c \"import sys;build=(sys.argv[1] if len(sys.argv) ==2 else sys.exit('please provide number as input'));print((next if build[1] == (next:= str(int(build) + 1))[0] else f'{int(next[0])*11}{next[1:]}'))\""

alias micromamba-fhs="nix-shell -E 'with import <nixpkgs> {}; (pkgs.buildFHSUserEnv {name = \"micromamba-fhs\"; runScript=\"zsh\";}).env'"

alias fhs="nix-shell -E 'with import <nixpkgs> {}; (pkgs.buildFHSUserEnv {name = \"micromamba-fhs\"; runScript=\"zsh\";}).env'"
# https://discourse.nixos.org/t/why-is-it-so-hard-to-use-a-python-package/19200/20
# alias fhs="nix shell --impure --expr '((builtins.getFlake \"nixpkgs\").legacyPackages.\${builtins.currentSystem}.buildFHSUserEnv { name = \"fhs\"; runScript=\"zsh\"; }).env'"


alias utvpn-tmux="tmux new-session -d -s vpn 'utvpn' && tmux attach -t vpn"
