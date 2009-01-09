#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfile]"; exit 1; }
[ -f timediff.txt ] || { echo "NEED timediff.txt"; exit 1; }
set - `date -f timediff.txt +%s`
diff=$(( $1 - $2 ))
echo DIFF=$diff

IFS=$'\n'

for line in `cat $1`; do
    IFS=$' '
    set - $line
    time="${1:0:6} ${1:7:2}:${1:9:2}:${1:11:2}"
    shift
    body="$*"
    crnt=`date -d "$time" +%s`
    echo "$crnt $body"
done