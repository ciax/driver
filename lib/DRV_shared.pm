#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Data convert and communication timing module
# Last Update 2007/6/7 Insert wait after device close in getraw.
# 2006/10/25 Insert wait between snd and rcv
# 2005/10/17 Return if no parameter
# 2004/6/17
package DRV_shared;
use strict;
use DB_device;
my %PKGS=();

sub new($%){
    my($pkg,%mpar)=@_;
    my $this={};
    %{$this->{mpar}}=%mpar;
    $this->{rdv}=new DB_device($mpar{dev});
    $this->{wait}=$this->{rdv}->getwait;
    my $mod="DRV_$mpar{ctype}";
    eval "use $mod";
    bless $this,$mod;
    $this->init;
    return $this;
}

sub getresp($$){
    my ($this,$str)=@_;
    return if($str eq "");
    my $res=$this->{rdv}->convert($this->getraw($str));
    return $res;
}

sub getraw($$){
    my ($this,$str)=@_;
    return if($str eq "");
    $str=$this->{rdv}->getcompstr($str);
    $this->open;
    $this->snd($str);
    select(undef,undef,undef,$this->{wait});
    my $res=$this->rcv;
    $this->close;
    select(undef,undef,undef,$this->{wait});
    return $res;
}

sub sendonly($$){
    my ($this,$str)=@_;
    return if($str eq "");
    $str=$this->{rdv}->getcompstr($str);
    my $exw=$this->{rdv}->res;
    $this->open;
    $this->snd($str);
    $this->rcv if($exw);
    $this->close;
    select(undef,undef,undef,$this->{wait});
}

sub recvonly($){
    my ($this)=@_;
    $this->open;
    my $res=$this->rcv;
    $this->close;
    select(undef,undef,undef,$this->{wait});
    return $res;
}

########## Interface #########
sub init($){}
sub open($){}
sub close($){}
sub snd($$){}
sub rcv($){}
sub end($){}
1;
