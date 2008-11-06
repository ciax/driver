#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2005/10/26 Warn handling
# 2003/2/27
package UDP_client;
#use strict;
use Socket;

sub new($$$){
    my($pkg,$host,$port)=@_;
    my $this={};
    my $S=rand;
    $this->{rver}=new MTN_ver("$host:$port%3","udpc");
    $this->{rver}->statprt("CL:Host=$host,Port=$port");
    if(!$this->{rver}->istest("CL:Test Mode")){
	socket($S,PF_INET,SOCK_DGRAM,getprotobyname('udp'));
	$port = getservbyname($port,'udp') unless($port =~ /^\d+/);
	$this->{ent} = sockaddr_in($port,inet_aton($host));
	select($S); $| =1; select(STDOUT);
	vec($this->{bits},fileno($S),1)=1;
	$this->{hdl}=$S;
    }
    bless $this;
}

### Set and Get Status
sub snd($$){
    my ($this,$str)=@_;
    return 1 if($this->{rver}->istest("CL:send $str(test)"));
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    select(undef,$bits,undef,2);
    if(vec($bits,fileno($S),1)){
	$this->{rver}->statprt("CL:send $str");
	send($S,$str,0,$this->{ent}) or return;
	$this->{rver}->statprt("CL:send done");
	return 1;
    }
    return;
}

sub rcv($$){
    my ($this,$timeout)=@_;
    return if($this->{rver}->istest("CL:recv(test)"));
    my ($stat)=();
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    select($bits,undef,undef,$timeout);
    if(vec($bits,fileno($S),1)){
	$this->{rver}->statprt("CL:recv ready");
	recv($S,$stat,1000,0);
	$this->{rver}->statprt("CL:recv ".substr($stat,0,20));
    }
    return $stat;
}

sub rcvsel($$){
    my ($this,$handle)=@_;
    return if($this->{rver}->istest("CL:select $handle"));
    select($handle);$|=1;select(STDOUT);
    my ($stat,$flg)=();
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    vec($bits,fileno($handle),1)=1;
    select($bits,undef,undef,undef);
    if(vec($bits,fileno($S),1)){
	recv($S,$stat,1000,0);
	$flg=$S;
    }elsif(vec($bits,fileno($handle),1)){
	$stat=<$handle>;
	$flg=$handle;
    }
    $this->{rver}->statprt("HANDLE [$flg]:".substr($stat,0,20));
    return ($flg,$stat);
}
1;
