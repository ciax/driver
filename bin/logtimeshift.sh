#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfiles]"; exit 1; }
ts="timeshift.txt"
[ -f $ts ] || (ssh ciax date;date) > $ts
diff=$(set - $(date -f $ts +%s);echo $(( $2 - $1 )))
for file ; do
    echo "DIFF = $diff sec"
    IFS=$'\n'
    for l in $(< $file); do
	old="${l:0:6} ${l:7:2}:${l:9:2}:${l:11:2}"
	new=$(date -d "$old $diff second ago" +%y%m%d-%H%M%S)
	if [ ! "$newfile" ] ; then
	    newfile="${file%-*}-${new%-*}.log"
	    [ -f $newfile ] && rm $newfile
	fi
	echo "$new${l:13}" >> $newfile
    done
    echo "$newfile is created!"
done