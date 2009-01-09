#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfiles]"; exit 1; }
ts="timeshift.txt"
[ -f $ts ] || (ssh ciax date;date) > $ts
diff=$(set - $(date -f $ts +%s);echo $(( $2 - $1 )))
echo "DIFF = $diff sec"
temp=".tmp$(date +%s).log"
for file ; do
    IFS=$'\n'
    begin=""
    for l in $(< $file); do
	old="${l:0:6} ${l:7:2}:${l:9:2}:${l:11:2}"
	new=$(date -d "$old $diff second ago" +%y%m%d-%H%M%S)
	[ "$begin" ] || begin=${new%-*}
	echo "$new${l:13}" >> $temp
    done
    end=${new%-*}
    newfile="${file%%-*}-$begin-$end.log"
    mv $temp $newfile
    echo "$newfile is created!"
done
