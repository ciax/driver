#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/6/29 Using SYS_date
# 2003/12/9
package SVR_stat;
use strict;
use SVR_shared;
@SVR_stat::ISA=qw(SVR_shared);
use CLI_stat;
use SYS_shmem;
use EXE_mlp;
use EXE_css;
use SYS_date;
my $wait=3;

sub new($){
    my($pkg)=@_;
    my $this=new SVR_shared;
    $this->{rmod}=new DB_mode("cst");
    bless $this;
}

############## COLLECT STATUS ###########
sub collect($){
    my($this)=@_;
    $this->SUPER::server;
    $this->{msl}=new SYS_shmem($this->{rmod}->getmpar,1);
    my @modes=$this->cst_init;
    $this->{rver}->statprt("Collect:".join(",",@modes));
    $this->server('css');
    $this->server('mlp');
    while(1){
	foreach (@modes,'css','mlp'){
	    my $stat=$this->getstat($_);
	    $stat=~tr/ /_/;
	    $this->{stat}{$_}=$stat;
	    $this->{msl}->putshm($_,$stat);
	}
	sleep $wait;
    }
}

########### SERVER ############
sub server($$){
    my($this,$mode)=@_;
    my %mod=$this->{rmod}->getmpar($mode);
    $this->{rver}->statprt("SERVER:$mode");
    return if($this->cfork($mode));
    $this->SUPER::server($mod{port});
    while(1){
	$this->{rver}->statprt("SUBSERVER:$mode");
	my $cmd=$this->{udp}->rcv($wait);
	next unless($cmd);
	my $data=$this->{msl}->getshm($mode);
	$this->{udp}->snd($data) if($data);
    }
}

sub getstat($$){
    my($this,$mode)=@_;
    my $stat="";
    if($mode =~ /now/){
	$stat=timestamp;
    }elsif($mode =~ /css/){
	$stat=$this->{rcss}->getcss(%{$this->{stat}}); 
    }elsif($mode =~ /mlp/){
	$stat=$this->{rmlp}->getmlp(%{$this->{stat}});
    }else{
	$stat=$this->{rst}->getstat($mode);
    }    
    $this->{rver}->statprt("SHMDATA:$mode [$stat]");
    return $stat;
}

############ CST #############
sub cst_init($){
    my($this)=@_;
    $this->{pointer}=0;
    $this->{rst}=new CLI_stat;
    $this->{rcss}=new EXE_css;
    $this->{rmlp}=new EXE_mlp;
    my @modes=($this->{rcss}->getmodes,"now");
    foreach (@modes){
	my $len=$this->{rmod}->getdb("len",$_);
	$this->{rver}->statprt("CST_INIT:$_($len)");
	$this->{msl}->newshm($_,$len);
	my $stat=$this->getstat($_);
	$stat=~tr/ /_/;
	$this->{msl}->putshm($_,$stat);
	$this->{stat}{$_}=$stat;
    }
    $this->svinit('css',$this->{rcss}->getcss(%{$this->{stat}}));
    $this->svinit('mlp',$this->{rmlp}->getmlp(%{$this->{stat}}));
    return @modes;
}

############ SVINIT ##############
sub svinit($$$){
    my($this,$mode,$stat)=@_;
    $this->{msl}->newshm($mode,length($stat));
    $this->{msl}->putshm($mode,$stat);
    $this->{rver}->statprt(uc($mode)."_INIT");
}

## $SIG{INT} Handle routine
sub svstop($){
    my ($this)=@_;
    $this->{msl}->endshm;
    $this->SUPER::svstop;
}
1;
