#!/usr/bin/perl -wc
# NT Station file sharing protocol control module
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/1/12 Insert wait into the loop
# 2004/7/13
package DRV_fsc;
@ISA=qw(DRV_shared);
use strict;
use SYS_file;

############## exporting subroutines ##############
sub init($){
    my ($this)=@_;
    my $obj=$this->{mpar}{cpar};
    die "NO OBJ!" if(!$obj);
    $this->{dbg}=new MTN_ver("$obj%6","fsc");
    $this->{rstrb}=new SYS_file("strb$obj.nt","n");
    $this->{rack}=new SYS_file("ack$obj.unx","n");
    $this->{sstrb}=new SYS_file("strb$obj.unx","n");
    $this->{sack}=new SYS_file("ack$obj.nt","n");
    $this->{rdys}=new SYS_file("readyU","n");
    $this->{rdyd}= new SYS_file("readyO","n");
    $this->{dmy}=new SYS_file("resp$obj.nt","n");
    $this->{timeout}=5;
    @{$this->{cmd}}=();
    @{$this->{data}}=();
    $this->{rdys}->wri("1O..");
    $this->{rack}->wri("0unx");
    $this->{sstrb}->wri(0);
}

# Recieve msg loop
sub rcv($){
    my($this)=@_;
    my $timeup=$this->{timeout}+time;
    my $data="";
    my $lastcmd=pop @{$this->{cmd}};
    my @ok=grep (/$lastcmd/,@{$this->{data}});
    my @ng=grep (!/$lastcmd/,@{$this->{data}});
    my $resp=shift @ok;
    if($resp){
	@{$this->{data}}=(@ok,@ng);
	return $resp;
    }
    while($timeup > time){
	my $data=$this->_msg;
	return $data if($data =~ /$lastcmd/);
	push @{$this->{data}},$data;
    }
    return shift @{$this->{data}};
}

sub _msg($){
    my($this)=@_;
    my ($ackf,$strbf,$data)=($this->{rack}->fname,$this->{rstrb}->fname);
    my $timeup=$this->{timeout}+time;
    my ($aflg,$sflg)=($this->{rack}->chkflg);
    my $msg1="RECV1:[$strbf=1,$ackf=0] Accepting $strbf from";
    my $msg2="RECV2:[$strbf=1,$ackf=1] Waiting for sending sign from";
    my $msg3="RECV3:[$strbf=0,$ackf=1] Complete recieving from";
    my $msg0="RECV0:[$strbf=0,$ackf=0] Ready for sending sign from";
    do{
	my ($resp)=$this->{rstrb}->red;
	($sflg,my $smsg,my $sfile)=unpack("AA8A12",$resp);
	if($sflg.$aflg eq "00"){
	    $this->{dbg}->statprt($msg0);
	}elsif($sflg.$aflg eq "10"){
	    $this->{dbg}->statprt($msg1);
	    $this->{dbg}->datprt($strbf,"$sflg $smsg $sfile <-");
	    $this->{rack}->wri("1unx");$aflg=1;
	}elsif($sflg.$aflg eq "11"){
	    $this->{dbg}->statprt($msg2);
	}elsif($sflg.$aflg eq "01"){
	    $this->{dbg}->statprt($msg3);
	    if($sfile){
		my $datfile=new SYS_file("$sfile","n");
		($data)=$datfile->red;
		$this->{dbg}->datprt($sfile,"$data <-");
	    }
	    $this->{rack}->wri("0unx");$aflg=0;
	}
	if($timeup < time){
	    warn("Time UP!\n");
	    return $data; 
	}
	select(undef,undef,undef,0.01);
    }until($sflg.$aflg eq "00" and $data);
    return $data;
}

############## send subroutines ##############

sub snd($$){
    my($this,$cmd)=@_;
    my ($smsg,$sfile,$data)=split(":",$cmd);
    $data=$this->convert($smsg,$data);
    my $datfile= new SYS_file("$sfile","n") if($sfile);
    my ($sflg,$aflg)=($this->{sstrb}->chkflg);
    my ($strbf,$ackf,$flg)=($this->{sstrb}->fname,$this->{sack}->fname);
    my $timeup=$this->{timeout}+time;
    my $msg1="SEND1:[$ackf=0,$strbf=0] Initializing to";
    my $msg2="SEND2:[$ackf=0,$strbf=1] Waiting for accept sign from";
    my $msg3="SEND3:[$ackf=1,$strbf=1] Complete sending to";
    my $msg4="SEND4:[$ackf=1,$strbf=0] Waiting for ready to accepting from";
    do{
	$aflg=$this->{sack}->chkflg;
	if($aflg.$sflg eq "00" and $smsg){
	    $this->{dbg}->statprt($msg1);
	    $datfile->wri($data) if($sfile);
	    $this->{sstrb}->wri(pack("AA8A23",1,$smsg,$sfile));$sflg=1;
	    $this->{dbg}->datprt($strbf,1,$smsg,$sfile,"->");
	}elsif($aflg.$sflg eq "01"){
	    $this->{dbg}->statprt($msg2);
	}elsif($aflg.$sflg eq "11"){
	    $this->{dbg}->statprt($msg3);
	    $this->{sstrb}->wri(pack("AA8A23",0,$smsg,$sfile));
	    $this->{dbg}->datprt($sfile,$data,"->") if($sfile);
	    push @{$this->{cmd}},$smsg;
	    ($sflg,$smsg)=(0);
	}elsif($aflg.$sflg eq "10"){
	    $this->{dbg}->statprt($msg4);
	}
	return if($timeup < time);
	select(undef,undef,undef,0.01);
    }until($aflg.$sflg eq "00");
    return 1;
}

# command replace for contents of a file
sub convert($$$){
    my ($this,$smsg,$data)=@_;
    if($smsg=~ /setmove/){
	my $cmd1=pack("A16",$data)."\r\n";
	my $cmd2=pack("A16","99Z00000")."\r\n";
	$data=$cmd1.$cmd2;
    }elsif($smsg=~ /runctrl/){
	$data=pack("A6",$data)."111111111";
    }
    return $data;
}

# generate dummy status
sub getdmy($){
  my ($this)=@_;
  my($stat)=$this->{dmy}->red;
  my ($rsp,$err,$etc)=unpack("A8A6A*",$stat);
  return pack("A8A6A*",$rsp,"dummy",$etc);
}
1;
