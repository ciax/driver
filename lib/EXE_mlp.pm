#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/3/4
package EXE_mlp;
use strict;
use DB_shared;
use MTN_ver;
use SYS_file;

sub new($){
    my($pkg)=@_;
    my $this={};
    $this->{rpk}=new SYS_file("cfg_mlp.txt","c");
    $this->{rver}=new MTN_ver("MLP%1","mlp");
    $this->{rid}=new DB_shared("db_inst.txt");
    bless $this;
}

sub getmlp($%){
    my ($this,%stat)=@_;
    %{$this->{stat}}=%stat;
    my (@devs,%upk,%slen)=();
    foreach ($this->{rpk}->red){
	my ($id,$ofs,$pck,$len)=split(",");
	$upk{$id}=$pck;
	$slen{$id}=$len;
	push @devs,$id;
	$this->{ofs}{$id}=$ofs;
    }
    my %sign=("0"=>"+","1"=>"-");
    my @results=("3A");
    foreach my $dev (@devs){
	my ($i,@rslt)=();
	my $local=$this->_getlocal($dev);
	my $upkstr=$upk{$dev};
	my @pkstr=split(/ /,$upkstr);
	$upkstr =~ s/b/A/g;
	$upkstr =~ s/%.//g;
	my @strs=unpack($upkstr,$local);    
	foreach(@pkstr){
	    my $pks=shift @strs;
	    $pks=unpack("h",pack($_,$pks)) if(/b/);
	    # Transfer
	    next if(/%o/);
	    $pks=sprintf("%02d",$this->{rid}->getdb("num",$pks)) if(/%i/);
	    $pks=$sign{$pks} if(/%s/);
	    push @rslt,$pks;
	}
	my $line=join("",@rslt);
	my $len=length($line);
	$this->{rver}->statprt("$dev = $local\n-->\t$line : $len/$slen{$dev}");
	push @results,$line;
    }
    my $result=uc(join("",@results));
    $this->{rver}->statprt("byte =".length($result)."/367");
    return "%mlp_00_".$result;
}

sub _getlocal($$){
    my($this,$dev)=@_;
    return "00" if($dev =~ /dmy/);
    my $stat=$this->{stat}{$dev};
    if($stat !~ /^%/){
	my $sfile=new SYS_file("ctl_$dev.st","s");
	($stat)=$sfile->red;
    }
    my ($offset,$length,$reverse)=split(/:/,$this->{ofs}{$dev});
    my $local="";
    if($length){
	$local=substr($stat,$offset,$length); 
    }else{
	$local=substr($stat,$offset); 
    }
    return reverse($local) if($reverse);
    return $local;
}
1;
