#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2008/11/10 branch from UDP_client
package DRV_udp;
use DRV_shared;
@ISA=qw(DRV_shared);
use Socket;

sub init($){
    my($this)=@_;
    my ($host,$port)=split(":",$this->{mpar}{cpar});
    die ("NO Host name for TCP connection!\n") unless($host);
    my $S=rand;
    $this->{rver}=new MTN_ver("$host:$port%3","udp");
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
	$this->{rver}->statprt("CL:length ".length($str));
	send($S,$str,0,$this->{ent}) or return;
	$this->{rver}->statprt("CL:send done");
	return 1;
    }
    return;
}

sub rcv($$){
    my ($this)=@_;
    return if($this->{rver}->istest("CL:recv(test)"));
    my ($stat)=();
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    select($bits,undef,undef,2);
    if(vec($bits,fileno($S),1)){
	$this->{rver}->statprt("CL:recv ready");
	recv($S,$stat,1000,0);
	$this->{rver}->statprt("CL:recv ".substr($stat,0,20));
	$this->{rver}->statprt("CL:length ".length($stat));
    }
    return $stat;
}
1;
