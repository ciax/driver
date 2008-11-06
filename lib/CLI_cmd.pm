#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/10/30 Send stop when Ctr-C if stop provided on cmd
# 2006/3/9 Add stat:sym
# 2003/5/9
package CLI_cmd;
use strict;
use UDP_client;
use DB_cmd;
use SYS_date;

sub new($%){
    my($pkg,%mpar)=@_;
    my $this={};
    $this->{fst}=new SYS_file("ctl_$mpar{mode}.st","s");
    $this->{udp}=new UDP_client($mpar{host},$mpar{port});
    $this->{rcmd}=new DB_cmd($mpar{mode},$mpar{usage});
    $this->{rcmd}->insdb("!A,---------- Daemon Command ----------",
	"stat,Get Status and Print",
	 "stat:csv,Get CSV Status,1",
	 "stat:raw,Get RAW Status,1",
	 "stat:sym,Get SYM Status,1",
	 "reset,Daemon Reset");
    $this->{self}=$mpar{self};
    bless $this;
}

### Set and Get Status for FST
sub setcmd($$$){
    my ($this,$cmd,$wait)=@_;
    return unless($this->{rcmd}->setkey($cmd));
    $this->{setstop}=($this->{rcmd}->getdb("stop") ne "");
    my $stat="";
    if($this->{udp}->snd($cmd) ne ""){
	$stat=$this->{udp}->rcv(3);
	if($wait > 0 and $cmd !~ /stat/){
	    $SIG{INT}=sub{$this->emstop};
	    warn("Ctrl-C for Stop!\n") if($this->{setstop});
	    for(my $i=0;$i<10000;$i++){
		last if($stat=$this->isend);
		select(undef,undef,undef,0.1);
	    }
	    $SIG{INT}=undef;
	}
    }else{
	warn("Status Error [$stat]\n");
    }
    return $stat if($cmd=~/stat:/);
    if($stat ne ""){
	$this->wstat($stat);
    }else{
	($stat)=$this->{fst}->red;
	$stat=substr($stat,14);
	substr($stat,4,1)="E" if(length($stat) > 4);
    }
    return $stat;
}

sub isend($){
    my ($this)=@_;
    $this->{udp}->snd("stat");
    my $stat=$this->{udp}->rcv(3);
    return $stat if(substr($stat,4,4) =~ /E/);
    return $stat if(substr($stat,5,2) !~ /1/);
    select(undef,undef,undef,0.1);
    return;
}

sub emstop($){
    my ($this)=@_;
    if($this->{setstop}){
	$this->{udp}->snd("stop");
	warn("Emergency Stop!\n");
    }
    exit;
}

sub wstat($$){
    my($this,$stat)=@_;
    return if($this->{self});
    my $body=substr($stat,14);
    return if($this->{stat} eq $stat);
    $this->{stat}=$stat;
    $this->{fst}->wri(timestamp." $stat");
}
1;
