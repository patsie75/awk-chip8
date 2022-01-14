#!/usr/bin/env bash

if [[ $# -lt 1 ]]; then
  echo "Usage: chip8.sh <program.ch8>" >&2
  exit 1
fi

stty=$(which stty)
function _exit() { "$stty" "$saved"; }

saved="$("$stty" -g)"
"$stty" -echo raw isig

trap _exit EXIT

clear
/usr/bin/gawk -bf ./main.gawk "$@"
