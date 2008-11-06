#!/usr/bin/perl -wc
# Dependency level 2
# Last update 2006/6/23

package VAR_queue;
use strict;
use SYS_file;

sub new($$$){
    my($pkg,$id,$max)=@_;
    my $this={id=>$id};
    $this->{max}=$max || 100;
    $this->{qf}=new SYS_file("queue_$id.txt","p");
    bless $this;
}

sub set($@){
    my($this,@array)=@_;
    $this->{qf}->wri(@array);
    return 1;
}

sub get($){
    my($this)=@_;
    return $this->{qf}->red;
}

sub queue($$){
    my($this,$data)=@_;
    return if($data eq "");
    my @array=$this->get;
    unshift(@array,$data);
    pop @array while(scalar @array > $this->{max});
    $this->set(@array);
    return @array;
}
1;
