#!/bin/bash
logdir=/export/scr/arc-pub/log
read
tar xzf $logdir/$1.tgz
logren $1*.log
tar cvzf $1.tgz $1*.log 
ls -al $1.tgz $logdir/$1.tgz
read
mv $1.tgz $logdir/log/
echo rm logs?
read
del  $1*.log 
