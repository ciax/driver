#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/3/21 Take one more parameter (Numerical)
# 2004/8/4
package DB_cmd;
use strict;
use DB_shared;
@DB_cmd::ISA=qw(DB_shared);

### Free characters ;|/^~_$
### Priority of separator on upd ,& 
### Priority of separator on cmd ,/&:
### Device using characters 0-9A-Za-z?!@:%()*+-=." "
### Special characters
###    <> substitute file contents
###    \FF substitute non-visible character
###    %X represents channel of I/O
###    %X substitute certain stat on Macro
###    {%X.X} substitute numeric parameter formatted by sprintf

sub new($$$){
    my($pkg,$mode,$usage)=@_;
    my $this=new DB_shared("cdb_{000,$mode}*.txt",$usage);
    $this->{mode}=$mode;
    bless $this;
}

sub setkey($$){
    my($this,$key)=@_;
    ($key,$this->{numeric})=split(":",$key);
    return $this->SUPER::setkey($key);
}

sub getdb($$$){
    my($this,$field,$key)=@_;
    my $str=$this->SUPER::getdb($field,$key) || return;
    $str=~s/\{(.+)\}/sprintf($1,$this->{numeric})/eg;
    return $str;
}
1;
