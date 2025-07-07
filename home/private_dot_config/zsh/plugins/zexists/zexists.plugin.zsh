#!/usr/bin/env zsh

function source-zshcmdd {
  setopt extended_glob

  # glob search for the zshcmd.d dir
  local -a zshcmdd=()
  [[ -n "$ZSHCMDD" ]] && zshcmdd+=($ZSHCMDD(N))
  [[ -n "$ZDOTDIR" ]] && zshcmdd+=($ZDOTDIR/exists.d/cmd(N))
  zshcmdd+=(${ZDOTDIR:-$HOME}/zexists.d/cmd(N))

  if ! (( $#zshcmdd )); then
    echo >&2 "zexists: dir not found '${ZSHCMDD:-${ZDOTDIR:-$HOME}/zexists.d/cmd}'"
    return 1
  fi
  local -a conf_files=("$zshcmdd[1]"/*.{sh,zsh}(N))
  local rcfile
  local antircfile
  # sort and source conf files
  for rcfile in ${(o)conf_files}; do
    # ignore files that begin with a tilde and antircfiles
    case ${rcfile:t} in 'anti'* | '~'*) continue;; esac
    # source files only if exe with that name exists
    if (( $+commands[${rcfile:t:r}] )); then
      source "$rcfile"
    else
      # if it doesn't exist try the anti version
      antircfile=${rcfile:h}/anti-${rcfile:t}
      [ -f $antircfile ] && source $antircfile
    fi
  done
}

function zshdir-decode {
  # for now just remove the 'dir' part
  echo ${${1//-SLASH-//}/-DOT-/\.}
}

function zshdir-encode {
  # dir is hardcoded...
  echo dir${${1//${HOME}\//}//\//-SLASH-}
}

function source-zshpathd {
  setopt extended_glob

  # glob search for the zshcmd.d dir
  local -a zshpathd=()
  [[ -n "$ZSHPATHD" ]] && zshpathd+=($ZSHPATH(N))
  [[ -n "$ZDOTDIR" ]] && zshpathd+=(
    $ZDOTDIR/zexists/path(N)
  )
  zshpathd+=(${ZDOTDIR:-$HOME}/zexists.d/path(N))

  if ! (( $#zshpathd )); then
    echo >&2 "zexists: dir not found '${ZSHPATHD:-${ZDOTDIR:-$HOME}/zexists.d/path}'"
    return 1
  fi

  local -a conf_files=("$zshpathd[1]"/*(N))
  local rcfile
  local name
  local pathtype
  local directory
  local antircfile  # sort and source conf files

  for rcfile in ${(o)conf_files}; do

    if [[ ${rcfile:t} == "dir"* ]];then
      pathtype='dir'
    elif [[ ${rcfile:t} == "file"* ]];then
      pathtype='file'
      echo >&2 "zexists: file type not yet supported"
    else
      echo >&2 "zexists: unknown path type for ${rcfile}"
      return 1
    fi

    # ignore files that begin with a tilde
    case ${rcfile:t} in '~'*) continue;; esac
    # remove 'dir' from name
    name=${${rcfile:t}/${pathtype}-/}
    directory=$HOME/$(zshdir-decode ${name})
    # source files only if exe with that name exists
    if [[ -d $directory ]]; then
      # echo "$directory"
      source $rcfile
    else
      # TODO: antirc naming broken
      # # if it doesn't exist try the anti version
      # antircfile="${rcfile:h}/anti-${pathtype}-${rcfile:t}"
      # [[ -f $antircfile ]] && source $antircfile
    fi

  done

}

source-zshcmdd
source-zshpathd
