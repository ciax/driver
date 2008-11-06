#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/1/6
package CTL_inst;
use strict;
@CTL_inst::ISA=qw(CTL_shared);

sub init($){
    my($this)=@_;
    my %cart=(ist=>"CART3",hst=>"CART2");
    my %pl=(ist=>"S",hst=>"H");
    $this->{cart}=$cart{$this->{mpar}{mode}};
    $this->{iref}=new SYS_file("inst$pl{$this->{mpar}{mode}}.txt","s");
    ($this->{status})=$this->{iref}->red;
    $this->{dref}=new SYS_file("setJak$pl{$this->{mpar}{mode}}.def","s");
}

sub drvctl($$){
    my ($this,$lcmd)=@_;
    return if($lcmd=~ /none/);
    my ($crnt,%i,$home)=();
    my($ifile,$inst,$ofile)=split(':',$lcmd);
    ($crnt,$i{SA},$i{SB},$i{SC},$i{SD},$home)=unpack("A6"x5 . "A2",$this->{status});
    my $iref=new SYS_file($ifile,"s");
    my @lines=$iref->red;
    if($inst){
        @lines=grep(/$this->{cart}:($inst|CHG)/,@lines); 
	$crnt=$inst;
    }	
    if($ofile){
        my $oref=new SYS_file($ofile,"s");
	$oref->wri(@lines);
    }
    my $repl=$this->_packjak(@lines);
    $this->{dref}->wri($repl);
    if($ifile =~ /setJak/){
        my ($dmy,$sym)=split(/[_\.]/,$ifile);
	my ($line)=grep(/(CAS|OPSM)/,@lines);
	my ($ct,$ins,$fl)=split(/:/,$line);
	$crnt=$ins;
	$home=$sym;
    }elsif($ofile =~ /setJak/){
        my ($dmy,$sym)=split(/[_\.]/,$ofile);
	$i{$sym}=$inst;
	$home=$sym;
    }
    $this->{status}=pack("A6"x5 . "A2",$crnt,$i{SA},$i{SB},$i{SC},$i{SD},$home);
    $this->{status}=~ tr/ /_/;
    $this->{iref}->wri($this->{status});
}

sub getstat($){
    my ($this)=@_;
    ($this->{status})=$this->{iref}->red;
    return $this->{status};
}

# Packing the Jack Data for setJak.def
sub _packjak($@){
    my ($this,@data)=@_;
    my @lcts=("CAS","MOV.OPT","FIX.OPT","MOV.IR","FIX.IR","CHG.OPT","CHG.IR");
    my $resp="1";
    $lcts[0]="OPSM" if(!grep(/CAS/,@data));
    foreach my $l (@lcts){
	my ($dat)=grep(/$l/,@data);
	$dat=$l if(!$dat);
	$resp.=$this->_spljak($dat); 
    }
    return $resp;
}

sub _spljak($$){
    my ($this,$str)=@_;
    return "0"x72 if($str eq "");
    my $resp=undef;
    my ($id,$dat)=split(',',$str);
    my @lvs=split(/:/,$dat);
    my @base=();
    foreach(0..3){
	my $lv=shift(@lvs);
	$lv=1 if(!$lv);
	$resp.=sprintf("%03d",$lv)."000";
	push @base,$lv;
    }
    if($id !~ /CHG/){
	foreach(1..2){
	    my $lv=shift @lvs;
	    $lv=1 if(!$lv);
	    foreach(0..3){
		$base[$_]+=$lv;
		$resp.=sprintf("%03d",$base[$_])."000";
	    }
	}
    }
    return $resp;
}
1;


