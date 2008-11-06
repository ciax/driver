#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2005/10/3 Stop the count if die
# 2004/7/13

package DRV_tcp;
use DRV_shared;
@ISA=qw(DRV_shared);
use Socket;

my $buffer=1024;
my $timeout=10;

sub new{
    my ($pkg,$id)=@_;
    my $this={};
    $this->{mpar}{cpar}=$id;
    bless $this;
    $this->init;
    return $this;
}

sub init($){
    my ($this)=@_;
    my ($host,$port)=split(":",$this->{mpar}{cpar});
    die ("NO Host name for TCP connection!\n") unless($host);
    $this->{host}=$host;
    $this->{port}=$port;
    my $S="S$port".time;
    $this->{dbg}=new MTN_ver("$host:$port%2",'tcp');
    $this->{dbg}->statprt("CL:Host=$host,Port=$port,HDL=$S");
    return 1 if($this->{dbg}->istest("Test Mode!"));
    socket($S,PF_INET,SOCK_STREAM,getprotobyname('tcp')) || die("socket : $!");
    $port = getservbyname($port,'tcp') unless($port =~ /^\d+/);
    die("No port") unless($port);
    my $ent = sockaddr_in($port,inet_aton($host));
    $this->{dbg}->statprt("CL:Try to Connect");
    $this->{dbg}->count_start(10);
    connect($S,$ent) || $this->{dbg}->count_stop("connect : $!");
    $this->{dbg}->count_stop;
    select($S); $| =1; select(STDOUT);
    vec($this->{bits},fileno($S),1)=1;
    $this->{hdl}=$S;
    $this->{dbg}->statprt("CL:Open");
}

### Set and Get Status
sub snd($$){
    my ($this,$str)=@_;
    return 1 if($this->{dbg}->istest("CL:send [$str](test)"));
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    select(undef,$bits,undef,$timeout);
    if(vec($bits,fileno($S),1)){
	$this->{dbg}->statprt("CL:send [$str]");
	syswrite($S,$str,$buffer) or return;
	$this->{dbg}->statprt("CL:send done");
	return 1;
    }else{
	$this->{dbg}->statprt("CL:send error");
	return;
    }
}

sub rcv($){
    my ($this)=@_;
    return "TEST" if($this->{dbg}->istest("CL:recv [TEST] (test)"));
    my ($stat)=();
    my $bits=$this->{bits};
    my $S=$this->{hdl};
    select($bits,undef,undef,$timeout);
    if(vec($bits,fileno($S),1)){
	$this->{dbg}->statprt("CL:recv ready");
	while(vec($bits,fileno($S),1)){
	    my $st;
	    sysread($S,$st,$buffer);
	    $stat.=$st;
	    $this->{dbg}->statprt("CL:recv recieving");
	    select($bits,undef,undef,0.1);
	}
	$this->{dbg}->statprt("CL:recv [$stat]");
	return $stat;
    }else{
	$this->{dbg}->statprt("CL:recv timeout");
	return;
    }
}

sub end($){
    my ($this)=@_;
    return if($this->{dbg}->istest("CL:closed(test)"));
    my $S=$this->{hdl};
    close($S);
    $this->{dbg}->statprt("CL:closed");
}

sub open{}
sub close{}
1;
