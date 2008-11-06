#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2005/10/25 Warn handling
# 2004/12/4

package UDP_server;
#use strict;
use Socket;

sub new($$$){
    my($pkg,$port,$mode)=@_;
    my $this={};
    my $s=rand;
    $this->{rver}=new MTN_ver("localhost:$port%5","udps");
    $port = getservbyname($port,'udp') unless($port =~ /^\d+/);
    socket($s,PF_INET,SOCK_DGRAM,getprotobyname('udp')) || die "socket: $!";
    my $ent = sockaddr_in($port, INADDR_ANY);
    bind($s, $ent) || die "bind: $!";
    select($s); $| =1; select(STDOUT);
    $this->{rver}->statprt("SV:Host=localhost,Port=$port");
    $this->{rver}->warning("[$mode] UDP PORT=$port");
    $this->{hdl}=$s;
    bless $this;
}

sub rcv($$){
    my($this,$timeout)=@_;
    my ($data,$bits)=();
    $this->{rver}->statprt("SV:recv ready");
    my $s=$this->{hdl};
    vec($bits,fileno($s),1)=1;
    select($bits,undef,undef,$timeout);
    if(vec($bits,fileno($s),1)){
	$this->{from} = recv($s,$data,1000,0);
	next if($this->{from} eq "");
	my ($port,$ipaddr) = sockaddr_in($this->{from});
	my $client = inet_ntoa($ipaddr);
	$this->{rver}->statprt("SV:recv from $client ".substr($data,0,20));
	chomp $data;
	return $data;
    }
    return 0;
}

sub snd($$){
    my($this,$str)=@_;
    die("No data!") if($str eq "");
    $this->{rver}->statprt("SV:send $str");
    my $bits="";
    my $s=$this->{hdl};
    vec($bits,fileno($s),1)=1;
    select(undef,$bits,undef,2);
    send($s,$str,0,$this->{from}) || die "send : $!";
    $this->{rver}->statprt("SV:send done");
}
1;
