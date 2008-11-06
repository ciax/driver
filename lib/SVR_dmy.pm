#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/8/14
package SVR_dmy;
use strict;
use DB_mode;
use SVR_shared;
@SVR_dmy::ISA=qw(SVR_shared);
use SYS_file;

sub new($$){
    my($pkg,$mode)=@_;
    my $rmod=new DB_mode($mode);
    $rmod->ishost(1);
    my %mpar=$rmod->getmpar;
    my $this=new SVR_shared(%mpar);
    $this->{rdmy}=new SYS_file("ctl_$mode.org","d");
    bless $this;
}

sub server($){
    my($this)=@_;
    return if($this->SUPER::server($this->{port}));
    my ($dmy)=$this->{rdmy}->red;
    while(1){
	my $data=$this->{udp}->rcv;
	$this->{udp}->snd($dmy) if($data);
    }
}

sub svstop($){
    my ($this)=@_;
    $this->SUPER::svstop;
}
1;
