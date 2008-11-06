#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/12/4
package SVR_mcr;
use strict;
use SVR_shared;
use EXE_mcr;
@SVR_mcr::ISA=qw(EXE_mcr);

sub new($){
    my($pkg)=@_;
    my $this=new EXE_mcr(1,"mcrs");
    $this->{rsv}=new SVR_shared;
    bless $this;
}

sub server($){
    my($this)=@_;
    return if($this->{rsv}->server($this->{port}));
    while(1){
	$this->setmcr($this->input);
    }
}

sub input($$){
    my($this,$tout)=@_;
    return $this->{rsv}{udp}->rcv($tout);
}
 		
sub prt($$){
    my($this,$str)=@_;
    return $this->{rsv}{udp}->snd($str);
}
1;
