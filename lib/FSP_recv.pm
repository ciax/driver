#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/1/12 Insert wait to loop
# 2002/12/27
package FSP_recv;
use SYS_file;

############## exporting subroutines ##############
sub new($$){
    my($pkg,$obj)=@_;
    die "NO OBJ!" if(!$obj);
    my $this ={get=>0};
    $this->{dbg}=new MTN_ver("$obj%6","ntd");
    $this->{strb}=new SYS_file("strb$obj.nt","n");
    $this->{ack}=new SYS_file("ack$obj.unx","n");
    bless $this;
}

sub init($){
    my($this)=@_;
    $this->{ack}->wri("0unx");
}

sub loop($){
    my($this)=@_;
    while($this->msg ne 3){
	select(undef,undef,undef,0.01);
    };
    return $this->get;
}

sub flush($){
    my($this)=@_;
    while($this->msg ne 0){};
    return $this->get if($this->{get});
    return "";
}

sub get($){
    my($this)=@_;
    $this->{get}=0;
    return ($this->{smsg},$this->{data});
}

# Recieve msg loop
sub msg($){
    my($this)=@_;
    my ($resp)=$this->{strb}->red;
    my ($sflg,$smsg0,$sfile0)=unpack("AA8A12",$resp);
    my $aflg=$this->{ack}->chkflg;
    my $flg=$sflg.$aflg;
    my $ackf=$this->{ack}->fname;
    my $strbf=$this->{strb}->fname;
    if($flg eq "00"){
        $this->{dbg}->statprt("RECV0:[$strbf=0,$ackf=0] Waiting for sending sign from");
	return 0;    
    }
    if($flg eq "10"){
	$this->{dbg}->statprt("RECV1:[$strbf=1,$ackf=0] Accepting $strbf from");
	if(!$this->{get}){
	    $smsg=$smsg0;
	    $sfile=$sfile0;
	    $this->{dbg}->datprt($this->{strb}{file},"$sflg $smsg $sfile <-");
	    if($sfile){
		my $datfile=new SYS_file("$sfile","n");
		($data)=$datfile->red;
		$this->{dbg}->datprt($sfile,"$data <-");
	    }
	    $this->{ack}->wri("1unx");
	}
	return 1;
    }
    if($flg eq "11"){
	$this->{dbg}->statprt("RECV2:[$strbf=1,$ackf=1] Waiting for sending sign from");
	return 2;
    }
    if($flg eq "01"){
	$this->{dbg}->statprt("RECV3:[$strbf=0,$ackf=1] Complete recieving from");
	$this->{ack}->wri("0unx");
	$this->{smsg}=$smsg;
	$this->{data}=$data;
	$this->{get}=1;
    }
    return 3;
}
1;
