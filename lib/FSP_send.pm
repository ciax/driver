#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/1/12 Insert wait to loop
# 2002/12/27
package FSP_send;
use SYS_file;

############## exporting subroutines ##############
sub new($$$){
  my($pkg,$obj)=@_;
  die "NO OBJ!" if(!$obj);
  my $this ={};
  bless $this;
  $this->{dbg}=new MTN_ver("$obj%3","ntd");
  $this->{strb}=new SYS_file("strb$obj.unx","n");
  $this->{ack}=new SYS_file("ack$obj.nt","n");
  return $this;
}

sub init($){
  my($this)=@_;
  $this->{strb}->wri(0);
}

sub loop($$$$){
  my($this,$smsg,$sfile,$data,$timeout)=@_;
  my $i=0;
  $this->{smsg}=$smsg;
  $this->{sfile}=$sfile;
  $this->{data}=$data;
  while($this->msg ne 2){
      if($i++ > $timeout){
	  $this->{strb}->wri(0);
	  return 0; 
      }
      select(undef,undef,undef,0.01);
  }
  return 1;
}

# Send message loop
sub msg($){
  my($this)=@_;
  my ($smsg,$sfile,$data)=($this->{smsg},$this->{sfile},$this->{data});
  return 0 if(!$smsg);
  my ($strbf,$ackf)=($this->{strb}->fname,$this->{ack}->fname);
  my $sflg=$this->{strb}->chkflg;
  my $aflg=$this->{ack}->chkflg;
  my $flg=$aflg.$sflg;
  if($flg eq "00"){
    $this->{dbg}->statprt("SEND1:[$ackf=0,$strbf=0] Initializing to");
    if($sfile){
      my $datfile= new SYS_file("$sfile","n");
      $datfile->wri($data);
    }
    $this->{strb}->wri(pack("AA8A23",1,$smsg,$sfile));
    $this->{dbg}->datprt($strbf,1,$smsg,$sfile,"->");
    return 0;
  }
  if($flg eq "01"){
    $this->{dbg}->statprt("SEND2:[$ackf=0,$strbf=1] Waiting for accept sign from");
    return 1;
  }
  if($flg eq "11"){
    $this->{dbg}->statprt("SEND3:[$ackf=1,$strbf=1] Complete sending to");
    $this->{strb}->wri(pack("AA8A23",0,$smsg,$sfile));
    $this->{dbg}->datprt($sfile,$data,"->") if($sfile);
    ($this->{smsg},$this->{sfile},$this->{data})=();
    return 2;
  }
  if($flg eq "10"){
    $this->{dbg}->statprt("SEND0:[$ackf=1,$strbf=0] Waiting for ready to accepting from");
    return 3;
  }
}
1;
