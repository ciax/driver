#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/3/21 Accept . and :
# Dependency level 0
# 2005/11/18 Add specification of inputrc file
# 2003/5/13
package SYS_term;
use strict;
use Term::ReadLine;

sub new($$){
  my($pkg,$inputrc)=@_;
  my $this ={};$|=1;
  $ENV{INPUTRC}="$ENV{DRVDIR}/config/$inputrc" if($inputrc);
  $this->{rterm}=new Term::ReadLine("shell");
  bless $this;
}

sub prompt($$){
    my($this,$prm)=@_;
    my $input=$this->{rterm}->readline("$prm>");
    $input=~ tr/ \-=.:0-9A-Za-z//cd;
    return $input;
}
1;
