#!/usr/bin/perl -wc
# RS control module for SUN-OS
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/7/13
package DRV_rss;
@ISA=qw(DRV_shared);
#use strict;
use DRV_rsctl;

sub init($){
    my($this)=@_;
    $this->{rver}=new MTN_ver("$this->{mpar}{dev}%A","rs");
    $this->{rver}->statprt("[open device=$this->{mpar}{dev}]");
}
 
#OPEN Serial
sub open($){
    my($this)=@_;
    if(!$this->{rver}->istest("[RS OPEN](test)")){
	$this->{hdl}=rand;
	open($this->{hdl}, "+</dev/$this->{mpar}{cpar}") || die("Can't open $this->{mpar}{cpar} $!");
	$this->termios(eval("DRV_rsctl::$this->{mpar}{ctype}"));
	select($this->{hdl});$|=1;select(STDOUT);
	vec($this->{bits},fileno($this->{hdl}),1)=1;
    }    
    return $this;
}

######## RS-232C module ########
sub snd($$){
    my($this,$str)=@_;
    return if($this->{rver}->istest("[$str]->(test)"));
    $this->{rver}->statprt("[$str]->");
    my $len=length($str);
    if(select(undef,$this->{bits},undef,1)){
	syswrite($this->{hdl},$str,$len); 
    }else{
	$this->{rver}->statprt("SEND Timeout");
    }
}

sub rcv($){
    my($this)=@_;
    return "TEST" if($this->{rver}->istest("[TEST]<-(test)"));
    my $res="";
    while(select($this->{bits},undef,undef,1)){
	my $r="";
	sysread($this->{hdl},$r,512);
	$res.=$r;
    }
    $this->{rver}->statprt("SEND Timeout") unless($res);
    $this->{rver}->statprt("[$res]<-");
    return $res;
}

sub close($){
    my($this)=@_;
    return if($this->{rver}->istest("[RS CLOSED](test)"));
    close($this->{hdl});
    select(undef,undef,undef,$this->{wait}+0.1);
}

#### termios ####
sub termios($$){
    my($this,$ctlcode)=@_;
    # Don't set values of $termios such as $termios=0;
    my $termios_t = 'L L L L C4 C C C13';
    my ($vmin,$vtime)=(1000,10);
#  my $tcget=$this->tcget;
#  ioctl($this->{hdl},$tcget,$termio) || die "IOCTL ERROR";
    my $termio = pack($termios_t,0,0,$ctlcode,0,0,$vmin,$vtime);
    my $tcset=$this->tcset;
    ioctl($this->{hdl},$tcset,$termio) || die "IOCTL ERROR";
}

sub tcset($){
    my($this)=@_;
    my $type=`uname`;
    chomp $type;
    return &DRV_rsctl::TCSETA if($type =~ /Linux/);
    return &DRV_rsctl::TCSETS if($type =~ /SunOS/);
    die "Can't use serial device";
}

sub tcget($){
    my($this)=@_;
    my $type=`uname`;
    chomp $type;
    return &DRV_rsctl::TCGETA if($type =~ /Linux/);
    return &DRV_rsctl::TCGETS if($type =~ /SunOS/);
    die "Can't use serial device";
}
1;
