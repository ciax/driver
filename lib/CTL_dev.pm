#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2005/10/7 Debug- "||" using evaluation regards "0" as false
# 2005/10/4 No response => stop same port reading , data=>*******
# 2004/7/13
package CTL_dev;
use strict;
@CTL_dev::ISA=qw(CTL_shared);
use DB_iomask;
use DRV_shared;

sub init($){
    my($this)=@_;
    my $i=0;
    my %mpar=%{$this->{mpar}};
    foreach(split(" ",$this->{mpar}{cpar})){
         $mpar{cpar}=$_;
         $this->{rrs}[$i++]= new DRV_shared(%mpar);
    }	
    $this->{chnum}=$i;
    $this->{rio}= new DB_iomask($this->{mpar}{dev});
}

sub drvctl($$){
    my($this,$str)=@_;
    my $istr=$this->{rio}->input;
    foreach (split(/&/,$str)){
	next unless($_);
	if(/^%/){
	    my $input="";
	    $input=$this->{rrs}[0]->getraw($istr) if($istr); 
	    $_=$this->{rio}->ioset($_,$input);
	}
	$this->{rrs}[0]->sendonly($_);
    }
}

sub drvmon($$){
    my($this,$str)=@_;
    my $res=$this->{rrs}[0]->getresp($str);
    return $res;
}
### Command strings  XXX|&YYY&ZZZ|2 -> XXX sendonly,YYY as is, ZZZ resp length is 2
sub getstat($$){
    my($this,$str)=@_;
    my $res="";
    for(my $i=0;$i<$this->{chnum};$i++){
	my $tres="*";
        foreach (split(/&/,$str)){
	    if(!/\|/){
		$res.=$this->{rrs}[$i]->getresp($_);
		next;
	    }
	    my ($cmd,$len)=split(/\|/);
	    if($len<1){
		$this->{rrs}[$i]->sendonly($cmd);
		next;
	    }
	    $tres=$this->{rrs}[$i]->getresp($cmd) if($tres ne "");
	    if($tres ne ""){
		$res.=pack("A$len",$tres);
		next;
	    }
	    $res.='*' x $len;
	}
    }
    $res=~ s/ +$//;
    return $res;
}

sub end($){
    my($this)=@_;
    for(my $i=0;$i<$this->{chnum};$i++){
	$this->{rrs}[$i]->end;
    }	
    $this->SUPER::end;
}
1;
