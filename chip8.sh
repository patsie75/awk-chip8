#!/usr/bin/env bash

stty=$(which stty)
function _exit() { "$stty" "$saved"; }

saved="$("$stty" -g)"
"$stty" -echo raw isig

trap _exit EXIT

clear
/usr/bin/gawk -bf ./main.gawk
