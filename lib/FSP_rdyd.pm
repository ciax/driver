#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2001/10/17
package FSP_rdyd;

sub new($$){
  my($pkg,$dst)=@_;
  die "NO DST!" if(!$dst);
  my $this ={};
  $this->{rdy}= new SYS_file("ready$dst","n");
  bless $this;
}

# check ready 
sub check($){
  my($this)=@_;
  my $flg=$this->{rdy}->chkflg;
  warn ("Not ready ($this->{rdy}{file} = 0)\n") unless($flg);
  $flg;
}
1;
