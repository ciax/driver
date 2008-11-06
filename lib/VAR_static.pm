#!/usr/bin/perl -wc
# Dependency level 2
# Last update 2006/6/23

package VAR_static;
use strict;
use VAR_config;
use SYS_file;
@VAR_static::ISA=qw(VAR_shared);

sub new($$$){
    my($pkg,$id)=@_;
    my $this=new VAR_shared($id);
    $this->{df}=new VAR_config($id);
    $this->{cf}=new SYS_file("stat_$id.txt","p");
    bless $this;
    $this->gethash;
    return $this;
}

sub set($$$){
    my($this,$sym,$val)=@_;
    $this->gethash;
    $this->SUPER::set($sym,$val);
    $this->{cf}->wri($this->h2a(%{$this->{val}}));
    return 1;
}

sub get($$){
    my ($this,$sym)=@_;
    %{$this->{val}}=$this->gethash;
    return $this->{val}{$sym};
}

sub gethash($){
    my ($this)=@_;
    my %def=$this->{df}->gethash;
    %{$this->{val}}=(%def,$this->a2h($this->{cf}->red));
    return %{$this->{val}};
}

sub chkval($$$){
    my ($this,$sym,$val)=@_;
    %{$this->{val}}=$this->a2h($this->{cf}->red);
    return $this->SUPER::chkval($sym,$val);
}

1;
