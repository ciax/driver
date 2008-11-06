#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/8/11
package EXE_css;
use strict;
use DB_stat;

sub new($){
    my($pkg)=@_;
    my $this={};
    my $rsum=new SYS_file("cfg_css.txt","c");
    @{$this->{sum}}=$rsum->red;
    chomp @{$this->{sum}};
    my @modes=();
    foreach(@{$this->{sum}}){
	my ($mode)=split(":");
	next unless($mode =~ /^[a-z]/);
	push @modes,$mode if(!grep(/$mode/,@modes));
    }
    $this->{sdb}{$_}=new DB_stat($_) foreach(@modes);
    @{$this->{modes}}=@modes;
    bless $this;
}

sub getmodes($){
    my($this)=@_;
    return @{$this->{modes}};
}

sub getcss($%){
    my($this,%stat)=@_;
    my $res="";
    foreach (@{$this->{sum}}){
	next unless($_);
	my($mode,$key)=split(":");
	$this->{sdb}{$mode}->setdef($stat{$mode});
	my $smbl=$this->{sdb}{$mode}->getraw($key);
	$res.=$smbl;
    }
    return "%css_00_$res$stat{now}";
}
1;

