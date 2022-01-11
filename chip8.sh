#!/usr/bin/env bash

stty=$(which stty)
function _exit() { "$stty" "$saved"; }

saved="$("$stty" -g)"
#"$stty" -echo -istrip -inlcr -igncr -icrnl -ixon -ixoff -icanon -opost -iuclc -ixany -imaxbel -xcase min 1 time 0
"$stty" -echo raw isig

trap _exit EXIT

/usr/bin/gawk -bf ./main.gawk
