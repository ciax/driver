#!/usr/bin/perl -wc
# Command dispatcher
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/8/21
package CTL_nt;
use strict;
@CTL_nt::ISA=qw(CTL_shared);
use DRV_shared;
use SYS_file;

sub init($){
    my($this)=@_;
    $this->{rcom}=new DRV_shared(%{$this->{mpar}});
    my $mode=$this->{mpar}{mode};
    $this->{cexe}=new SYS_file("exe_$mode.txt","s") if($mode =~ /ct$/);
    $this->{start}=$this->{rcmd}->getdb("cmdstr","start");
}

sub drvctl($$){
    my($this,$str)=@_;
    my $resp=$this->getstat($str);
    $this->{cexe}->wri("101") if($str =~ /run/);
    $this->{cexe}->wri("011") if($str =~ /lft/);
    if($str =~ /setmove/){
	$this->getstat($this->{start});
    }
}

sub drvmon($$){
    my($this,$str)=@_;
    my $res=$this->{rcom}->recvonly;
    return $res;
}

sub getstat($$){
    my($this,$cmd)=@_;
    my $resp=$this->{rcom}->getraw($cmd);
    if($resp =~ /step/){
	$this->{rcom}->recvonly;
	$resp=$this->{rcom}->getraw($this->{start});
    }
    if(exists $this->{cexe}){
	my ($cexe)=$this->{cexe}->red;
	$cexe=$this->{cexe}->wri("001") if($resp =~ /(end|step)/);
	$cexe=$this->{cexe}->wri("001") if($cexe =~ /000/);
	$cexe=$this->{cexe}->wri("000") if($resp =~ /err/);
	$resp.=$cexe;
    }      
    return $resp;
}

#sub new2($){
#    my($pkg)=@_;
#    my $this=new CTL_shared;
#    $this->{cexe}="001";
#    ($this->{exec},$this->{isu},$this->{sflg},$this->{cerr})=(0,0,0,"_");
#    @{$this->{cmd}}=("upd");
#    bless $this;
#}
#
#sub operation($$){
#    my($this,$cmd)=@_;
#    $this->regcmd($cmd);
#    $this->putcmd;
#    $this->getstat;
#}
#
#sub dispatch($){
#    my($this)=@_;
#    $this->cdpwstat;
#}
#
# Command recieve from client
#sub regcmd($$){
#    my($this,$data)=@_;
#    return unless($data);
#    return if($data eq "stat");
#    if($data eq "reset"){
#	$this->init("upd");
#	return;
#    }
#    @{$this->{cmd}}=() if($data =~ /(stop|reset)/);
#    push @{$this->{cmd}},$data;
#}
#
############ Internal Modules #############
#
# Command issue to station
#sub drvctl($$){
#    my($this,$cmd)=@_;
#    return if(!$cmd);
#    my $data=$this->{rcmd}->getdb("cmdstr",$cmd);
#    if($this->{rcom}->setcmd($data)){
#	$this->{isu}=1;
#	$this->{exec}=1 if($data =~ /^setmove/);
#	($this->{cexe},$this->{sflg})=("101",1) if($cmd =~ /run/);
#	($this->{cexe},$this->{sflg})=("011",0) if($cmd =~ /lft/);
#	$this->{rlog}->rec($cmd,1);
#    }else{
#	$this->{cerr}="E";
#    }
#}
#
## Command dispatch with Status
#sub cdpwstat($){
#    my($this)=@_;
#    ($strb,$this->{resp})=$this->{rcom}->getstat;
#    $this->{resp} =~ s/ +$//g;
#    $this->{resp} =~ s/ {5}01001000$//g if($this->{mpar}{mode} =~ /nso/);
#    $this->{resp}.=$this->{cexe} if($this->{mpar}{mode} =~ /[nh]ct/);
#    if($strb){
#	my ($header,$local)=unpack("A20A*",$this->{resp});
#	$this->{alarm}=($local =~ /^0000/)?1:0;
#	my $remote=substr($local,3,1);
#	$this->{cerr}="_";
#	# Command Issued
#	$this->{isu}=0 unless($header =~ /step/);
#	# Cart (run,jack,remote) flags for MLP3
#	$this->{cexe}="001" if($header =~ /end/);
#	$this->{cexe}="001" if($this->{cexe} eq "000");
#	$this->{cexe}="000" if($header =~ /err/ or $this->{alarm} or !$remote);
#	# Executing flag set/reset
#	$this->{exec}=1 if($header =~ /(setmove|start|step)/);
#	$this->{exec}=0 if($header =~ /(err|end|reset)/ or $this->{alarm});
#	# Auto update flag (1=Ready 2=Auto)
#	$this->{sflg}=0 if($header =~ /(step|err|end)/ or $this->{alarm});
#	$this->{sflg}=1 if($header =~ /stop/ and $this->{sflg}==2);
#	$this->{sflg}=2 if($header =~ /start/ and $this->{sflg}==1);
#	$this->autocommand;
#    }
#    $this->{rlog}->rec($this->getstat,2) if($strb);
#}
#
#sub getstat($){
#    my($this)=@_;
#    my $msg=pack("AAA",$this->{exec},$this->{isu},$this->{cerr});
#    my $ntstat=pack("A5A*","%$this->{mpar}{mode}_",$msg.$this->{resp});
#    return $ntstat;
#}
#
## Command dispatching
#sub autocommand($){
#    my($this)=@_;
#    my ($header,$local)=unpack("A20A*",$this->{resp});
#    my $setadr=($this->{mpar}{mode} =~ /[nh]ct/ and $local =~ /^10010000/);
#    @{$this->{cmd}}=() if($header =~ /(stop|err|end)/);
#    @{$this->{cmd}}=("start") if($header =~ /(setmove|step)/);
#    @{$this->{cmd}}=("upd") if($header =~ /setpara/);
#    if($header =~ /status/){
#	if($this->{alarm}){
#	    @{$this->{cmd}}=("ntres"); 
#	}elsif($setadr and $this->{updcnt}<3){
#	    ($this->{sflg},$this->{exec})=(0,0);
#	    $this->{updcnt}++;
#	    @{$this->{cmd}}=("setadr");
#	}
#    }
#}
#
1;
