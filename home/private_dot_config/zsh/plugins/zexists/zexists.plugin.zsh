#!/usr/bin/env zsh

function source-zshcmdd {
  # Use local_options to prevent extended_glob from polluting the user's global shell state.
  setopt local_options extended_glob

  local -a zshcmdd=()
  
  # Build the array of target directories. 
  # (N) ensures the glob evaluates to an empty array instead of throwing an error if missing.
  [[ -n "$ZSHCMDD" ]] && zshcmdd+=("$ZSHCMDD"(N))
  [[ -n "$ZDOTDIR" ]] && zshcmdd+=("$ZDOTDIR/exists.d/cmd"(N))
  zshcmdd+=("${ZDOTDIR:-$HOME}/zexists.d/cmd"(N))

  if ! (( $#zshcmdd )); then
    print -u2 "zexists: dir not found '${ZSHCMDD:-${ZDOTDIR:-$HOME}/zexists.d/cmd}'"
    return 1
  fi

  local -a conf_files=("$zshcmdd[1]"/*.{sh,zsh}(N))
  local rcfile antircfile

  # Loop through files, sorted in ascending alphabetical order via (o).
  for rcfile in ${(o)conf_files}; do
    case ${rcfile:t} in 'anti'* | '~'*) continue;; esac
    
    # Evaluate if the command matching the filename (sans extension) exists in $PATH.
    if (( $+commands[${rcfile:t:r}] )); then
      # Synchronously source the file. This blocks prompt rendering.
      source "$rcfile"
    else
      # Fallback: Look for a corresponding 'anti-' file.
      antircfile="${rcfile:h}/anti-${rcfile:t}"
      [[ -f "$antircfile" ]] && source "$antircfile"
    fi
  done
}

function zshdir-decode {
  # Replaces '-SLASH-' with '/' and '-DOT-' with '.'
  echo "${${1//-SLASH-//}/-DOT-/\.}"
}

function zshdir-encode {
  # Hardcodes 'dir' prefix, removes $HOME prefix, and replaces '/' with '-SLASH-'
  echo "dir${${1//${HOME}\//}//\//-SLASH-}"
}

function source-zshpathd {
  setopt local_options extended_glob

  local -a zshpathd=()
  
  # Evaluate the custom variable $ZSHPATHD.
  [[ -n "$ZSHPATHD" ]] && zshpathd+=("$ZSHPATHD"(N))
  [[ -n "$ZDOTDIR" ]] && zshpathd+=("$ZDOTDIR/zexists/path"(N))
  zshpathd+=("${ZDOTDIR:-$HOME}/zexists.d/path"(N))

  if ! (( $#zshpathd )); then
    print -u2 "zexists: dir not found '${ZSHPATHD:-${ZDOTDIR:-$HOME}/zexists.d/path}'"
    return 1
  fi

  local -a conf_files=("$zshpathd[1]"/*(N))
  local rcfile name pathtype directory antircfile

  for rcfile in ${(o)conf_files}; do
    if [[ ${rcfile:t} == dir-* ]]; then
      pathtype='dir'
    elif [[ ${rcfile:t} == file-* ]]; then
      pathtype='file'
      # Skip unsupported files cleanly.
      print -u2 "zexists: file type not yet supported (${rcfile:t})"
      continue
    else
      print -u2 "zexists: unknown path type for ${rcfile:t}"
      continue
    fi

    case ${rcfile:t} in '~'*) continue;; esac

    name="${${rcfile:t}/${pathtype}-/}"
    directory="$HOME/$(zshdir-decode "$name")"
    
    if [[ -d "$directory" ]]; then
      # Synchronously source the file.
      source "$rcfile"
    else
      antircfile="${rcfile:h}/anti-${rcfile:t}"
      [[ -f "$antircfile" ]] && source "$antircfile"
    fi
  done
}

source-zshcmdd
source-zshpathd
