#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/10/8 convert ESC char to space at stat
# 2006/1/12 timeout ->1000
# 2002/4/21
package FSP_fspc;
use FSP_rdyd;
use FSP_rdys;
use FSP_send;
use FSP_recv;
use SYS_file;

sub new($$){
    my($pkg,$mode)=@_;
    die "NO MODE!" if(!$mode);
    my $this={};
    my %obj=(nct=>"W",nso=>"O",nsi=>"I",hct=>"W");
    $this->{obj}=$obj{$mode};
    $this->{rdys}=new FSP_rdys("U","O");
    $this->{rdyd}=new FSP_rdyd("O");
    $this->{snd}= new FSP_send($this->{obj});
    $this->{rcv}= new FSP_recv($this->{obj});
    bless $this;
}

sub init($){
    my ($this)=@_;
    $this->{rdys}->ready_on;
    $this->{snd}->init;
    $this->{rcv}->init;
}

### Set and Get for NT
sub getstat($){
    my ($this)=@_;
    my ($res,$stat)=$this->{rcv}->flush;
    $this->{stat}=$stat if($res);
    $this->{stat}=$this->getdmy if(!$this->{stat});
    $this->{stat}=~ tr/\0-\x1f/ /;
    return ($res,$this->{stat});
}

sub setcmd($$){
    my ($this,$str)=@_;
    return $this->getstat if(!$str);
    my ($smsg,$sfile,$data)=split(":",$str);
    if($smsg=~ /setmove/){
	my $cmd1=pack("A16",$data)."\r\n";
	my $cmd2=pack("A16","99Z00000")."\r\n";
	$data=$cmd1.$cmd2;
#    }elsif($smsg=~ /runctrl/){
#	$data=pack("A6",$data)."111111111";
    }
    my $exdata=$this->convert($data);
    $this->{snd}->loop($smsg,$sfile,$exdata,1000);
}

# command replace for contents of a file
sub convert($$){
  my ($this,$data)=@_;
    my ($exdata,@phase)=split(/\[/,$data);
    foreach(@phase){
        my ($fname,$lest)=split(/\]/);
        my $fsp=new SYS_file("$fname","s");
        my ($fdata)=$fsp->red;
        $exdata.=$fdata.$lest;
    }
    return $exdata;
}

# generate dummy status
sub getdmy($){
  my ($this)=@_;
  my $rsf=new SYS_file("resp$this->{obj}.nt","n");
  my($stat)=$rsf->red;
  my ($rsp,$err,$etc)=unpack("A8A6A*",$stat);
  return pack("A8A6A*",$rsp,"dummy",$etc);
}
1;
