#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Dependency level 0
# Last update 2006/3/9 Colmn 80 -> 72
# 2005/10/20 ADD a nocolor mode ($ENV{NOCOLR} is true)
# 2003/6/12
package SYS_stdio;
use strict;

sub new($){
  my($pkg)=@_;
  my $this ={};
  $|=1;
  bless $this;
}

##### STANDARD OUTPUT #####
### Formatted Print Out ###
sub prtindent($$$){
    my($this,$data,$col)=@_;
    print ("\t" x $col . $data . "\n");
}

sub prtlines($@){
    my($this,@lines)=@_;
    print "$_\n" foreach(@lines);
}

sub visible($$){
    my($this,$str)=@_;
    my $vstr="";
    foreach (split(//,$str)){
	my $num=unpack("C",$_);
	if($num > 0x1f and $num < 0x7f){
	    $vstr.=$_;
	}else{
	    my $vnum="(".sprintf("%02X",$num).")%4";
	    $vstr.=$this->color($vnum);
	}
    }
    return $vstr;
}

### Help output ###
sub helpout($@){
    my($this,@lines)=@_;
    my ($strlen,$chrlen,@help)=();
    foreach(@lines){
	next unless($_);
	my ($cmd,$caption)=split(',');
	if($cmd =~ /^!/){
	    $caption=$this->color("$caption%2");
	    push @help,"\t$caption";
	}elsif($cmd ne ""){
	    my $len=length($cmd.$caption);
	    $cmd=$this->color("$cmd%3");
	    my $unit="    $cmd : $caption";
	    ($strlen,$chrlen)=($len,length($unit)) if($len > $strlen);
	    push @help,$unit;
	}
    }
    my $column=($strlen >1) ? int(72/$strlen) : 1;
    my $col=1;
    foreach(@help){
	if($_ =~ /\t/){
	    print "\n" if($col != 1);
	    print "$_\n";
	    $col=1;
	}else{
	    print pack("A$chrlen",$_);
	    if($column < ++$col){
		$col=1;
		print "\n";
	    }
	}
    }
    print "\n" if($col != 1);
}

### Coloring Subroutine ###
# 1=RED,2=GREEN,4=BLUE,9=LIGHT RED,A=LIGHT GREEN,C=LIGHT BLUE
sub color($$){
    my($this,$data)=@_;
    return $data unless($data =~ /%([0-9A-Fa-f]*)$/);
    my ($str,$color)=($`,$1);
    return $str if($ENV{NOCOLOR});
    $color=1 unless($color);
    my $num=hex($color);
    my $msb=($num & 8)?0:1;
    my $col=$num & 7;
    return "\033[$msb;3${col}m$str\033[0m";
}
1;
