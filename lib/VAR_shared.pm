#!/usr/bin/perl -wc
# Dependency level 0
# Last update 2006/6/23

package VAR_shared;
use strict;

sub new($$$){
    my($pkg,$id)=@_;
    my $this ={id=>$id};
    %{$this->{val}}=();
    bless $this;
}

sub set($$$){
    my($this,$sym,$val)=@_;
    $this->{val}{$sym}=$val;
    return 1;
}

sub get($$){
    my ($this,$sym)=@_;
    return $this->{val}{$sym};
}

sub gethash($$){
    my ($this)=@_;
    return  %{$this->{val}};
}

sub chkval($$$){
    my ($this,$sym,$val)=@_;
    my ($max,$min)=("$sym:max","$sym:min");
    if(exists $this->{val}{$max}){
	if($val > $this->{val}{$max}){
	    $val=$this->{val}{$max};
	    return ($val,1);
	}
    }
    if(exists $this->{val}{$min}){
	if($val < $this->{val}{$min}){
	    $val=$this->{val}{$min};
	    return ($val,-1);
	}
    }
    return ($val,0);
}

######## Subroutine ########

sub round($$){
    my ($this,$val)=@_;
    return sprintf("%.3g",$val);
}

sub a2h($@){
    my ($this,@line)=@_;
    my %res=();
    foreach (@line){
	next unless($_);
	my($name,$val)=split(/=/,$_);
	$res{$name}=$val;
    }
    return %res;
}

sub h2a($%){
    my ($this,%a)=@_;
    my @res=();
    foreach (keys %a){
	next unless($_);
	push @res,"$_=$a{$_}";
    }
    return @res;
}
    
1;
