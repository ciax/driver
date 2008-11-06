#!/usr/bin/perl -wc
# RS control module for Linux
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last Update 2006/10/25 close wait=0.1
# 2004/7/13
package DRV_rsl;
@ISA=qw(DRV_shared);
#use strict;

sub init($){
    my ($this)=@_;
    $this->{rver}=new MTN_ver("$this->{mpar}{dev}%A","rs");
    $this->{stty}="stty -F /dev/$this->{mpar}{cpar} ".$this->{rdv}->getsttypar;
    $this->{rver}->statprt("[$this->{stty}]");
    $this->{raw}=1 if($this->{stty} =~ /raw/);
    $this->{wait}=$this->{rdv}->getwait;
    `$this->{stty}` unless($this->{rver}->istest("Test Mode!"));
}

######## RS-232C module ########
sub open($){
    my($this)=@_;
    return if($this->{rver}->istest("[RS OPEN](test)"));
    $this->{hdl}=rand;
    open($this->{hdl}, "+</dev/$this->{mpar}{cpar}")
	or die("Can't open $this->{mpar}{cpar}!");
    select($this->{hdl});$|=1;select(STDOUT);
    vec($this->{bits},fileno($this->{hdl}),1)=1;
    $this->{rver}->statprt("[RS OPEN]");
}

sub snd($$){
    my($this,$str)=@_;
    return if($this->{rver}->istest("[$str]->(test)"));
    my $hdl=$this->{hdl};
    if(! select(undef,$this->{bits},undef,1)){
	$this->{rver}->statprt("SEND Timeout");
	return;
    }
    if($this->{raw}){
	$this->{rver}->statprt("SEND RAW MODE");
	my $len=length($str);
	syswrite($hdl,$str,$len); 
    }else{
	$this->{rver}->statprt("SEND CANONICAL MODE");
	print($hdl $str);
    }
    $this->{rver}->statprt("[$str]->");
}

sub rcv($){
    my($this)=@_;
    return "TEST" if($this->{rver}->istest("[TEST]<-(test)"));
    my $hdl=$this->{hdl};
    if(! select($this->{bits},undef,undef,1)){
	$this->{rver}->statprt("RECV Timeout");
	return;
    }
    my $resp="";
    if($this->{raw}){
	$this->{rver}->statprt("RECV RAW MODE");
	sysread($hdl,$resp,512);
    }else{
	$this->{rver}->statprt("RECV CANONICAL MODE");
	$resp=<$hdl>;
    }
    $this->{rver}->statprt("[$resp]<-");
    return $resp;
}

sub close($){
    my($this)=@_;
    return if($this->{rver}->istest("[RS CLOSED](test)"));
    close($this->{hdl});
    $this->{rver}->statprt("[RS CLOSED]");
    select(undef,undef,undef,0.1);
}
1;
