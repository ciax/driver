#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2009/2/19
package CTL_cmd;
use strict;
@CTL_cmd::ISA=qw(CTL_shared);

sub init($){
    my($this)=@_;
    $this->{rver}=new MTN_ver("CMD%9","cmd");
    $this->{err}=0;
}

sub drvctl($$){
    my($this,$cmd)=@_;
    $this->{rver}->statprt("EXEC:$cmd");
    `$cmd`;
    my $err=$?;
    $this->{err}=$err/256;
    $this->{rver}->statprt("ERRCODE:$this->{err}");
    return if($err != 0);
    sleep 1;
}

sub getstat($$){
    my($this,$cmd)=@_;
    $this->{rver}->statprt("UPDATE:$cmd");
    my $stat=`$cmd`;
    $this->{rver}->statprt("STOUT:$stat");
    return substr($stat,8);
}
1;
