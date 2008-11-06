#!/usr/bin/perl -wc
# CLX Device Controller
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/7/13
package CTL_818;
use strict;
@CTL_818::ISA=qw(CTL_shared);
use DRV_shared;

sub init($){
    my($this)=@_;
    $this->{rio}= new DRV_shared(%{$this->{mpar}});
    my $ch=7;
    $this->{rio}->sendonly("O9\x0");  # Software Trigger
    $this->{ch}=$ch;
    $this->setrange($_,0) foreach (0..$ch);
    $this->setscan(0,$ch);
}

# Get AD Status Driver
sub getstat($){
    my ($this)=@_;
    my $av=$this->getdata;
    return unless($av);
    return pack("A24",$av);
}

############# Internal routine ################

# A/D converter program on Linux (PCL-818L)

# A/D range (0->5V,1->2.5V,2->1.25V,3->0.625V)
sub setrange($$$){
    my($this,$ch,$rng)=@_;
    $this->{rio}->sendonly("O2".pack("C",$ch));  # MUX set
    $this->{rio}->sendonly("O1".pack("C",$rng)); # A/D range (=5V)
}
# MUX set
sub setscan($$$){
    my($this,$start,$end)=@_;
    my $hex=$end*16+$start;
    $this->{rio}->sendonly("O2".pack("C",$hex));
}


######## Data get #########
sub getdata($){
    my($this)=@_;
    my ($ch,$dat,$resp)=(0);
    foreach (1..8){
	my $sum=0;
	($ch,$dat)=$this->getword;
	my $res=($dat-2048)/16;
	$res=0 if($res < 0);
	$resp .=sprintf("%03d",$res);
    }
    return $resp;
}


sub getword($){
    my($this)=@_;
    # Trigger 
    $this->{rio}->sendonly("O0\x1");
    my $i=0;
    for($i=0;$i<10;$i++){
	last if($this->{rio}->getraw("I8") & "\x10");
    }    
    return if($i == 10);
    my $inp=unpack("S",$this->{rio}->getraw("W0"));
    my $ch=$inp & 0x0f;
    my $dat=$inp >> 4;
    return ($ch,$dat);
}

sub indil($){
    my($this)=@_;
    return $this->{rio}->getresp("I3");
}

sub indih($){
    my($this)=@_;
    return $this->{rio}->getresp("Ib");
}
1;
