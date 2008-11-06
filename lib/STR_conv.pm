#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/12/23
package STR_conv;
use strict;

sub new($%){
    my($pkg,%key)=@_;
    my $this={%key};
    bless $this;
}

sub cond($$){
    my($this,$cond)=@_;
    if($cond =~ /=~/){
	my($key,$val)=split("=~",$cond);
	return 1 if($this->{$key} =~ /$val/);
    }elsif($cond =~ /!~/){
	my($key,$val)=split("!~",$cond);
	return 1 if($this->{$key} !~ /$val/);
    }elsif($cond =~ /==/){
	my($key,$val)=split("==",$cond);
	return 1 if($this->{$key} eq $val);
    }elsif($cond =~ /!=/){
	my($key,$val)=split("!=",$cond);
	return 1 if($this->{$key} ne $val);
    }
}
1;
