#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfile]"; exit 1; }
file="$1"
ts="timeshift.txt"
[ -f $ts ] || { echo "NEED $ts"; exit 1; }
set - `date -f $ts +%s`
diff=$(( $2 - $1 ))
echo "DIFF=$diff"

IFS=$'\n'

for line in `cat $file`; do
    IFS=$' '
    set - $line
    time="${1:0:6} ${1:7:2}:${1:9:2}:${1:11:2}"
    shift
    body="$*"
    new=`date -d "$time $diff second ago" +%y%m%d-%H%M%S`
    echo "$new $body"
done