#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/5/9
package CLI_stat;
use strict;
use DB_mode;
use DB_stat;
use UDP_client;

sub new($){
    my($pkg)=@_;
    my $this={};
    $this->{rmod}=new DB_mode('mcr');
    bless $this;
}

sub symbol($$){
    my ($this,$query)=@_;
    return unless($query);
    my($mode,$key)=split(":",$query);
    $this->getstat($mode);
    my $symcol=$this->{sdb}{$mode}->getsym($key);
    my $caption=$this->{sdb}{$mode}->getcaption($key);
    my ($sym)=split(/[!%]/,$symcol);
    $sym=~ tr/_//d;
    return ("$sym:".uc($mode).":$caption");
}

sub getstat($$){
    my($this,$mode)=@_;
    $this->openmode($mode);
    $this->{udp}{$mode}->snd('stat');
    my $stat=$this->{udp}{$mode}->rcv(3);
    if($stat){
	$this->wstat($mode,$stat);
    }else{
	($stat)=$this->{fst}{$mode}->red;
	substr($stat,4,1)="E" if(length($stat)>4);
    }
    $this->{sdb}{$mode}->setdef($stat);
    return $stat;
}

########### INTERNAL ############
sub openmode($$){
    my($this,$mode)=@_;
    if(not exists $this->{sdb}{$mode}){
	my %mod=$this->{rmod}->getmpar($mode);
	$this->{udp}{$mode}=new UDP_client($mod{host},$mod{port});
	$this->{sdb}{$mode}=new DB_stat($mode);
	$this->{fst}{$mode}=new SYS_file("ctl_$mode.st","s");
	$this->{self}{$mode}=$mod{self};
    }
}

sub wstat($$$){
    my($this,$mode,$stat)=@_;
    return if($this->{self}{$mode});
    return if($this->{stat}{$mode} eq $stat);
    $this->{stat}{$mode}=$stat;
    $this->{fst}{$mode}->wri($stat);
}
1;
