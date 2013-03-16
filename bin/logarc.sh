#!/bin/bash
warn(){ echo -e "\e[1;33m${*}\e[0m"; }
die(){ echo -e "\e[1;31m${*}\e[0m"; exit 1; }
[ "$1" ] || die "Usage:logarc (-n) [fileheader] (e.g. nct-05)"
#cd $HOME/var/log/ || die "No Var directory"
arcdir="/export/scr/arc-pub/document/log/"
[ -d $arcdir ] || die "No arc dir"
[ "$1" = "-n" ] && { noren=1; shift; }
tgzfile="$1.tgz"
[ "$noren" ] || logren.sh $1*.log || exit
[ -e $arcdir$tgzfile ] && tar xzf $arcdir$tgzfile
[ "$noren" ] || logren.sh $1*.log || exit
logfile=$1*.log
tar cvzf $tgzfile $logfile
ls -al $tgzfile || exit
if [ -e $arcdir$tgzfile ] ; then
    ls -al $arcdir$tgzfile
    warn "mv $tgzfile?"
    read repl
    [ "$repl" = "y" ] || { rm $tgzfile ; warn "$tgzfile was removed"; }
fi
[ -e $tgzfile ] && { tar tvzf $tgzfile ; mv $tgzfile $arcdir ; warn "$tgzfile was moved to $arcdir"; }

warn "rm logs?"
read repl
[ "$repl" = "y" ] && { mv $logfile ~/.trash && warn "logfiles were removed"; }
