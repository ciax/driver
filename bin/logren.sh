#!/bin/bash
[ -f "$1" ] || { echo "Usage: ${0##*/} [logfiles]"; exit 1; }
for fname ; do
    head=$(egrep "^[0-9]{6}-[0-9]{6}" $fname|head -n 1)
    tail=$(egrep "^[0-9]{6}-[0-9]{6}" $fname|tail -n 1)
    begin=${head%%-*}
    end=${tail%%-*}
    d1=${tail#* };d2=${d1#%}
    if [ $begin = $end ] ; then
        date="$begin"
    else
        date="$begin-$end"
    fi
    mode=${d2:0:3}
    [ "$mode" = "###" ] && mode=${head:19:3}
    newname="$mode-$date.log"
    if [ -f "$newname" ] ; then
        cmp -s $fname $newname || echo "$newname exists"
    else
        mv $fname $newname && echo "$fname ==> $newname"
    fi
done
