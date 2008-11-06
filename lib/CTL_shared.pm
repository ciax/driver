#!/usr/bin/perl -wc
# Copyright (c) 1997-2005, Koji Omata, All right reserved
# Last update:2007/1/25 isu=1 during drvmon
# 2006/12/21 print to warn
# 2006/9/20 Holding off EXE=0 timing
# 2006/6/29 Using SYS_date
# 2005/11/30 Add a timestamp to shm
# 2005/10/26 Warn handling
# 2005/10/4 No response data => *********
# 2005/9/27 Remove SQL logging
# 2005/9/23 Exit code handling
# 2004/12/7
package CTL_shared;
use strict;
use DB_cmd;
use MTN_ver;
use SYS_shmem;
use SYS_date;

# Issue -> stat X,stop X,other execute command X
# Exec -> stat O,stop O,other execute command X

sub new($%){
    my($pkg,%mpar)=@_;
    my $this={};
    %{$this->{mpar}}=%mpar;
    my $usage=($mpar{usage})?"$mpar{mode} [cmd]":"";
    $this->{rcmd}=new DB_cmd($mpar{mode},$usage);
    $this->{updstr}=$this->{rcmd}->getdb("cmdstr","upd");
    $this->{rver}=new MTN_ver("DEVCMD:$mpar{mode}%E","exe");
    my $modname="CTL_$mpar{dev}";
    $modname="CTL_dev" unless(-e "$ENV{DRVDIR}/lib/$modname.pm");
    eval "use $modname";
    bless $this,$modname;
}

sub driver($$){
    my ($this,$cmd)=@_;
    $this->errexit("No such command $this->{rcmd}{mode}:$cmd\n",10) unless($this->{rcmd}->setkey($cmd));
    my $lcmd=$this->{rcmd}->getdb("cmdstr") or return;
    $this->{msl}=new SYS_shmem(%{$this->{mpar}});
    $this->{msl}->initdev($this->{updstr});
    $this->init;
    return $this->putstat($this->{msl}->getshm("exe")) if($cmd =~ /upd/);
    $SIG{INT}=sub{$this->emstop};
    $SIG{TERM}=sub{$this->term};
    $this->{stopc}=$this->{rcmd}->getdb("stop");
    warn ("Ctrl-C for Stop!\n") if($this->{stopc} ne "");
    $this->{msl}->putshm("isu",0);
    my ($fst,$dlt,$lst)=split('/',$lcmd);
    $this->{rver}->statprt("Execute $fst");
    $this->drvctl($fst);
    my ($tout,@moncmd)=split(":",$dlt);
    if(scalar @moncmd){
	$tout+=time;
	$this->{rver}->statprt("Waiting for $moncmd[0]");
	my $stop=0;
	$this->{msl}->putshm("isu",1);
	until($stop){
	    $stop=1;
	    foreach(@moncmd){
		my $csep=(/==/)?"==":"=";
		my ($ccmd,$cval)=split(/$csep/);
		my $stat=$this->drvmon($ccmd);
		$this->{msl}->putshm($ccmd,$stat);
		if($cval ne ""){
		    $stop&=($stat eq $cval)?1:0;
		}
		select(undef,undef,undef,0.1);
	    } 
	    if(time > $tout){
		$this->{rver}->warning("Action Timeout!");
		last;
	    }
	}
	$this->{msl}->putshm("isu",0);
    }elsif(int($tout) > 0){
	$this->{rver}->statprt("Waiting $tout sec");
	sleep $tout;
    }	    
    if($lst ne ""){
	$this->{rver}->statprt("Execute $lst");
	$this->drvctl($lst);
    }
    $this->{msl}->putshm("isu",1);
    $this->{rver}->statprt("Execution End");
    ($SIG{TERM},$SIG{INT})=();
    $this->putstat(0);
}

sub putstat($$){
    my ($this,$exe)=@_;
    $exe=($exe)?"1":"0";
    my $ucmd=$this->{rcmd}->getdb("cmdstr","upd") or return;
    my $stat=$this->getstat($ucmd);
    $this->{rver}->statprt("[$stat]");
    my $repl=pack("A5","%$this->{mpar}{mode}_");
    $stat=$stat||"*" x $this->{mpar}{len};
    $this->{msl}->putshm("time",timestamp);
    if($stat !~ /^\*+$/){
	$stat=~ tr/ /_/;
	$stat=~ tr/\0-\x1f/\\/;
	chomp $stat;	
	my $len=($this->{mpar}{len}) ? $this->{mpar}{len}:"*";
	$repl.=pack("AA2A$len",$exe,"0_",$stat);
	$this->{msl}->putshm("body",$repl);
    }else{
	$repl.="00E".$stat;
	$this->{msl}->putshm("body",$repl);
	$this->errexit("NO response",4);
    }
    return $repl;
}

## $SIG{INT} Handle routine
sub emstop($){
    my ($this)=@_;
    $SIG{INT}=undef;
    my $scmd=$this->{stopc};
    my $lcmd=$this->{rcmd}->getdb("cmdstr",$scmd) if($scmd ne "");
    my $message="[$this->{mpar}{mode}] Stopped !";
    if($lcmd ne ""){
	$this->drvctl($lcmd);
	$message="[$this->{mpar}{mode}] Stopped with $scmd !";
    }
    $this->errexit($message,1);
}

sub term($){
    my ($this)=@_;
    $SIG{TERM}=undef;
    $this->errexit("[$this->{mpar}{mode}] timeout error!",2);
}

sub errexit($$$){
    my ($this,$message,$errcode)=@_;
    $this->{msl}->putshm("exe",0);
    $this->{rver}->warning($message);
    $this->end;
    exit $errcode;
}

## Interface
sub init($$){}
sub drvctl($$){}
sub drvmon($$){}
sub getstat($){
    my ($this)=@_;
    $this->{msl}->getshm("body");
}
sub end($){
    my ($this)=@_;
    $this->{msl}->putshm("isu",0);
}
1;
