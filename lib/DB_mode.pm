#!/usr/bin/perl -wc
# Copyright (c) 1997-2008, Koji Omata, All right reserved
# Update History
# 2008/2/25 hostname normalization
# 2006/2/9 Set mode to $ENV{MODE}
# 2005/10/4 Default initial mode is first key
# 2005/6/9 eliminate reading field "group"
# 2005/6/3 read db_mode by $ENV{PROJECT}
# 2005/4/29 (host=any can run anywhere) 
# 2003/12/9
package DB_mode;
use strict;
use DB_shared;
@DB_mode::ISA=qw(DB_shared);

sub new($$$){
    my($pkg,$mode,$usage)=@_;
    my $name=$0;
    $name=~ s/.*\///;
    my $this=new DB_shared("db_mode*$ENV{PROJECT}.txt",$usage);
    $this->{name}=$name;
    $this->{myhost}=`hostname`;
    $this->{myhost}=~s/\..*//;
    ($mode)=grep(/[\w]{3}/,$this->getkeys) if($mode.$usage eq "");
    chomp $this->{myhost};
    bless $this;
    $this->setmode($mode);
    return $this;
}

sub setmode($$){
    my($this,$mode)=@_;
    return unless($this->setkey($mode));
    $ENV{MODE}=$mode;
    $this->{mode}=$mode;
    $this->{host}=$this->getdb("host");
    $this->{self}=($this->{host}=~/^$this->{myhost}$/)?1:0;
    return $mode;
}

sub getmpar($$){
    my($this,$mode)=@_;
    $mode=$this->{mode} unless($mode);
    my %mpar=$this->gethash($mode);
    $mpar{mode}=$mode;
    $mpar{usage}=$this->{usage};
    $mpar{cpar}=$this->cparconv($mpar{cpar});
    $mpar{self}=($this->{myhost}=~/$mpar{host}/)?1:0;
    my @numc=split(/ /,$mpar{cpar});
    $mpar{len}=(@numc>0) ? $mpar{elen}*@numc : $mpar{elen};
    return %mpar;
}

sub ishost($$){
    my($this,$selfexit)=@_;
    return 1 if($ENV{VER} or $this->{self} or $this->{host}=~/any/);
    die("[$this->{mode}] is executable only on [$this->{host}]!\n")
	if($selfexit);
}

#################  FOR DEVICES  ################

sub cparconv($$){
    my($this,$cpar)=@_;
    my @cpars=split(" ",$cpar);
    my $str=shift @cpars;
    my @line=($str);
    foreach (@cpars){
	next unless($_);
	substr($str,-length($_))=$_;
	push @line,$str;
  }
  return join(" ",@line);
}
1;
