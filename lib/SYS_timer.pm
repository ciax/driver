#!/usr/bin/perl -wc
# Copyright (c) 1997-2006, Koji Omata, All right reserved
# Dependency level 1
# 2006/6/1 Created
# Last update:2007/8/22 add resetTimeout
# 2006/6/29 Using SYS_date
package SYS_timer;
use strict;
use SYS_stdio;
use SYS_date;

sub new($$$){
    my($pkg,$id,$duration)=@_;
    warn("Duration is $duration sec at $id\n");
    my $this={id=>$id,duration=>$duration,nextTime=>0,timeout=>0};
    $this->{rprt}=new SYS_stdio;
    $this->{name}=$this->{rprt}->color($id);
    bless $this;
}

sub resetTimer($){
    my($this)=@_;
    $this->{nextTime}=time+$this->{duration};
    $this->_errout("$this->{id} Reset Timer!");
}

sub checkTimer($){
    my($this)=@_;
    my $now=time;
    my $remain=$this->{nextTime}-$now;
    return if($this->{duration} > $remain and $remain > 0); 
    if(abs($remain)>$this->{duration}*10){
	$this->{nextTime}=$now;
    }
    while($this->{nextTime} <= $now){
	$this->{nextTime}+=$this->{duration};
    }
#    $this->_errout("$this->{id} Next Schedule:".timeform($this->{nextTime}));
    return 1;
}

## Timeout
sub isTimeout($){
    my($this)=@_;
    return unless($this->{timeout});
    return if(time < $this->{nextTime});
    $this->{timeout}=0; 
    $this->_errout("$this->{id} Timeout!");
    return 1;
}

sub setTimeout($){
    my($this)=@_;
    $this->{timeout}=$this->{duration};
    $this->{nextTime}=$this->{timeout}+time;
    return 1;
}

sub resetTimeout($){
    my($this)=@_;
    $this->{timeout}=0; 
}

# Counter
sub countStart($){
    my ($this)=@_;
    my $ppid=$$;
    $this->_errout("$this->{id} Counting start!");
    my @sig=($SIG{INT},$SIG{TERM});
    ($SIG{INT},$SIG{TERM})=();
    $this->{pid}=fork;
    my $timeout=time+$this->{duration};
    while(!$this->{pid}){
	my $count=$timeout-time;
	if($count<0){
	    $this->_errout("$this->{id} Timeout!");
	    kill(15,$ppid);
	    exit;
	}
	print STDERR "$this->{id} $count  \r";
	sleep 1;
    }
    ($SIG{INT},$SIG{TERM})=@sig;
}

sub countStop($$){
    my ($this,$str)=@_;
    kill(15,$this->{pid}) if($this->{pid});
    if($str){
	$this->_errout($str);
	exit 1;
    }
    $this->_errout("$this->{id} Counting finished!");
}

sub _errout($$){
    my($this,$str)=@_;
    warn(timestamp." $str\n");
}
1;
