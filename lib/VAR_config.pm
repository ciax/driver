#!/usr/bin/perl -wc
# Dependency level 2
# Last update 2006/6/23

package VAR_config;
use strict;
use VAR_shared;
use SYS_file;
@VAR_config::ISA=qw(VAR_shared);

sub new($$$){
    my($pkg,$id)=@_;
    my $this=new VAR_shared($id);
    $this->{cf}=new SYS_file("cfg_$id.txt","p");
    %{$this->{val}}=$this->a2h($this->{cf}->red);
    bless $this;
}

sub get($$){
    my ($this,$sym)=@_;
    %{$this->{val}}=$this->gethash;
    return $this->{val}{$sym};
}

sub gethash($){
    my ($this)=@_;
    %{$this->{val}}=$this->a2h($this->{cf}->red);
    return %{$this->{val}};
}
1;
