#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfiles]"; exit 1; }
for fname ; do
    head=$(head -n 1 $fname)
    tail=$(tail -n 1 $fname)
    begin=${head%%-*}
    end=${tail%%-*}
    if [ $begin = $end ] ; then
	date="$begin"
    else
	date="$begin-$end"
    fi
    mode=${tail:15:3}
    newname="$mode-$date.log"
    if [ -f $newname ] ; then
	cmp -q $fname $newname || echo "$newname exists"
    else
#	mv $fname $newname
	echo "$fname ==> $newname"
    fi
done
