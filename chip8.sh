#!/usr/bin/env bash

if [[ $1 == "--help" || $1 == "-h" ]]; then
  echo "Usage: chip8.sh <program>"
  exit 0
fi

stty=$(which stty)
function _exit() { "$stty" "$saved"; }

saved="$("$stty" -g)"
"$stty" -echo raw isig opost

trap _exit EXIT

clear
/usr/bin/gawk -bf ./main.gawk "$@"
