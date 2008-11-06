#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2002/7/22
package FSP_rdys;

# Src ready files open
sub new($$$){
  my($pkg,$src,$dst)=@_;
  die "NO SRC/DST!" if(!$src or !$dst);
  my $this={};
  $this->{rdys}=new SYS_file("ready$src","n");
  $this->{dst}=$dst;
  bless $this;
}
sub ready_on($){
  my($this)=@_;
  $this->{rdys}->wri("1$this->{dst}..");
}
sub ready_off($){
  my($this)=@_;
  $this->{rdys}->wri("0$this->{dst}..");
}
1;
