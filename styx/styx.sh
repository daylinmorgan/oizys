#!/usr/bin/env bash

set -e

TERM=${TERM:-dumb}
HOSTNAME=${HOSTNAME:-$(hostname)}
FLAKE_PATH=${FLAKE_PATH:-$HOME/nixcfg}

DIM="$(tput dim)"
BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
CYAN="$(tput setaf 4)"
RESET="$(tput sgr0)"
PREFIX="${CYAN}styx${RESET}"

log() {
	printf "%s | %s\n" "$PREFIX" "$*"
}

error() {
	printf "%s | %s | %s\n" "$PREFIX" "${RED}error${RESET}" "$*"
}

help() {
	cat <<EOF
styx <cmd> [-h]
  ${DIM}sister moon to nix on pluto
  sister software to nix in this repo${RESET}

${BOLD}commands${RESET}:
EOF
	printf "${GREEN}%8s${RESET} | ${YELLOW}%s${RESET}\n" \
    fmt "format *.nix" \
    build "build and monitor with nom" \
    boot "evaluate flake for next boot" \
    switch "perform nixos rebuild" \
    store "run some store cleanup" \
    cache "nix build and push to daylin.cachix.org"
	exit
}

fmt() {
	alejandra . "$@"
}

boot() {
	sudo nixos-rebuild boot --flake "$FLAKE_PATH" "$@"
}

switch() {
	sudo nixos-rebuild switch --flake "$FLAKE_PATH" "$@"
}

store() {
	nix store optimise "$@"
}

build() {
  nom build "$FLAKE_PATH#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"
  case "$1" in
    switch | boot | test ) sudo ./result/bin/switch-to-configuration "$1";;
  esac
}

dry() {
  # poor mans nix flake check
  nix build "$FLAKE_PATH#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel" --dry-run
}


cache() {
  start=$(date +%s)

  cachix watch-exec daylin \
    -- \
    nix build "$FLAKE_PATH#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel" \
    --print-build-logs \
    --accept-flake-config

  end=$(date +%s)
  runtime=$(date -d@$((end-start)) +'%M minutes, %S seconds')

  echo "Built host: ${HOSTNAME} in ${runtime} seconds" >> "$GITHUB_STEP_SUMMARY"
}


if [[ $# -eq 0 ]]; then
	log no command specified see below for help
	help
fi

while [[ $# -gt 0 ]]; do
	case $1 in
	fmt | boot | switch | store | build | dry | cache)
		cmd=$1
		shift
		;;
  -f | --flake)
    FLAKE_PATH="$2"
    shift; shift;
		;;
  -h | --host)
    shift
    HOSTNAME="$1"
    shift;
    ;;
  --help)
		help
    ;;
  --)
    shift
    break
		;;
	-*,--*)
		error "unknown flag: ${BOLD}$1${RESET}"
		exit 1
		;;
	*)
		error "unknown command: ${BOLD}$1${RESET}"
		exit 1
		;;
	esac
done

if [[ $# -gt 0 ]]; then
	echo "forwarding args: ${BOLD}$*${RESET}"
fi

if [[ -z ${cmd+x} ]]; then
  error "please specify a command"
  help
fi

$cmd "$@"