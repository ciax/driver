#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2005/10/18 Omit SRM1's reverse
# 2004/4/26
package DB_iomask;
use strict;

sub new($$){
    my($pkg,$type)=@_;
    my $this={type=>$type,ch=>0};
    bless $this;
}

sub input($){
    my ($this)=@_;
    if($this->{type} =~ /bbe/){
	return "0RD";
    }elsif($this->{type} =~ /725/){
	return "I0";
    }
}

## Command format:  % [<ch>] : ?=? : ?=? : ....
sub ioset($$$){
    my ($this,$iostr,$input)=@_;
    return $iostr if($iostr !~ /^%/);
    $iostr=substr($iostr,1);
    $input=reverse($input) if($this->{type} =~ /bbe/);
    $input="0"x16 if($this->{type} =~ /srm1/);
    ($input,$this->{mask})=("\0\0","\0\0") if($this->{type} =~ /fp/);
    $this->{input}=$input;
    my @cmds=();
    foreach(split(/&/,$iostr)){
	$this->setbit($_) foreach(split(/:/,$_));
	push @cmds,$this->output;
    }
    return join("&",@cmds);
}

sub setbit($$){
    my ($this,$iostr)=@_;
    return $this->{ch}=$iostr if($iostr !~ /=/);
    my ($adr,$set)=split(/=/,$iostr);
    if($this->{type} =~ /srm1/){
	substr($this->{input},15-$adr,1)=($set)?5:4;
	return;
    }
    vec($this->{mask},$adr,1)=1 if($this->{type} =~ /fp/);
    vec($this->{input},$adr,1)=$set;
}

sub output($$){
    my ($this)=@_;
    if($this->{type} =~ /fp/){
	my $out=unpack("v",$this->{input});
	my $msk=unpack("v",$this->{mask});
# i386 is little endian, sparc is little endian
# it is possible to be generated different results by running PCs
	return sprintf("%02X!L%04X%04X",$this->{ch},$msk,$out);
    }elsif($this->{type} =~ /srm1/){
	return sprintf('@00FKCIO %04d%s',$this->{ch},$this->{input});
    }elsif($this->{type} =~ /bbe/){
	return '0SO'.reverse($this->{input});
    }elsif($this->{type} =~ /725/){
	return "O0$this->{input}";
    }
}
1;
