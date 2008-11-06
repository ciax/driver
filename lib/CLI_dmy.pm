#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/3/22
package CLI_dmy;
use strict;
use DB_cmd;

sub new($%){
    my($pkg,%mpar)=@_;
    my $this={};
    $this->{fst}=new SYS_file("ctl_$mpar{mode}.org","d");
    $this->{rcmd}=new DB_cmd($mpar{mode},$mpar{usage});
    $this->{rcmd}->insdb("!A,---------- Daemon Command ----------",
	"stat,Get Status and Print",
	"reset,Daemon Reset");
    $this->{self}=$mpar{self};
    bless $this;
}

### Set and Get Status for FST
sub setcmd($$$){
    my ($this,$cmd,$wait)=@_;
    return unless($this->{rcmd}->setkey($cmd));
    my ($stat)=$this->{fst}->red;
    return $stat;
}

sub isend($){
    my ($this)=@_;
    $this->{udp}->snd("stat");
    my $stat=$this->{fst}->red;
    return $stat if(substr($stat,4,4) =~ /E/);
    return $stat if(substr($stat,5,2) !~ /1/);
    return;
}
1;
