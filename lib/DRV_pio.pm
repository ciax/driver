#!/usr/bin/perl -wc
# Linux I/O port Cntrol Module
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/7/13
package DRV_pio;
@ISA=qw(DRV_shared);
#use strict;

# Set Base I/O address
sub init($){
    my ($this)=@_;
    my $base=$this->{mpar}{cpar};
    $this->{base}=hex($base);
    $this->{rver}=new MTN_ver("$this->{mpar}{dev}:$base%A",'io');
    $this->{rver}->statprt("IO base address $base");
}

# I=>Input Byte, W=>Input Word, O=>Output
sub snd($$){
    my ($this,$str)=@_;
    my ($cmd,$offset,$chr)=unpack("aha",$str);
    if($cmd eq "I"){
	$this->{data}=$this->_in($offset,1);
    }elsif($cmd eq "W"){
	$this->{data}=$this->_in($offset,2);
    }elsif($cmd eq "O"){
	$this->_out($offset,1,$chr);
    }
}

sub rcv($){
    my ($this)=@_;
    return $this->{data};
}

##### Internal Subroutine #######
sub _out($$$$){
    my($this,$offset,$length,$chr)=@_;
    return if($this->{rver}->istest("Output[$offset($length)](test)->[$chr]"));
    my $addr=$offset+$this->{base};
    my $S="S".time;
    open($S,">/dev/port") or die("Can't open I/O port\n");
    seek($S,$addr,0);
    syswrite($S,$chr,$length);
    close($S);
    $this->{rver}->statprt("Output[$offset($length)]->[$chr]");
}

sub _in($$$){
    my ($this,$offset,$length)=@_;
    return if($this->{rver}->istest("Input[$offset($length)](test)->[TS]"));
    my $chr=undef;
    my $addr=$offset+$this->{base};
    my $S="S".time;
    open($S,"/dev/port") or die("Can't open I/O port\n");
    seek($S,$addr,0);
    sysread($S,$chr,$length);
    close($S);
    $this->{rver}->statprt("Input[$offset($length)]->[$chr]");
    return $chr;
}
1;
