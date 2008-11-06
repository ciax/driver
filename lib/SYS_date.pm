#!/usr/bin/perl -wc
# Copyright (c) 1997-2006, Koji Omata, All right reserved
# Dependency level 0
# Last update: ADD time difference of logtime
# 2006/6/29 Created
package SYS_date;
use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(timeform timestamp timediff);
use strict;
use Time::Local;

sub timeform($){
    my ($time)=@_;
    $time=time unless($time);
    my ($s,$mi,$h,$d,$mo,$y)=localtime($time);
    return sprintf("%02d%02d%02d-%02d%02d%02d",$y-100,$mo+1,$d,$h,$mi,$s);
}

sub timestamp{
    return timeform(time);
}

sub timediff(@){
    my @rawtime=();
    foreach (@_){
	my ($date,$time)=split("-",$_);
	my ($h,$mi,$s)=unpack("A2A2A2",$time);
	my ($y,$mo,$d)=unpack("A2A2A2",$date);
	push @rawtime,timelocal($s,$mi,$h,$d,$mo-1,$y+100);
    }
    return $rawtime[0]-$rawtime[1];
}
1;
