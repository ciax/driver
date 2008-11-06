#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/8/10
package CTL_tsc;
use strict;
@CTL_tsc::ISA=qw(CTL_shared);

sub init($){
    my($this)=@_;
    $ENV{OSS_SYSTEM}="/app/OSS/GLOBAL_DEBUG/OSS_SYSTEM";
    $ENV{OSSL_LOG}="/app/oss_data/OBS_NFS";
    $ENV{OSS_CMDPATH}="/app/LOAD/DEBUG";
    $ENV{OSS_OBS_HOST}="cxws";
    $ENV{PATH}="$ENV{OSS_SYSTEM}:$ENV{OSS_CMDPATH}:$ENV{PATH}";
    $this->{rver}=new MTN_ver("TSC%9","tsc");
    $this->{err}=0;
    my $fsp=new SYS_file("cfg_tscst.txt","c");
    my $ucmd="";
    foreach($fsp->red){
	my ($str,$byte)=split(",");
	$ucmd.=$str." ";
	push @{$this->{bts}},$byte;
    }
    $this->{ucmd}="OSSC_screenPrint -R ".$ucmd;
}

sub drvctl($$){
    my($this,$str)=@_;
    my $cmd="";
    if($str =~ /^CMD/){
	my($dmy,$timeout,$num)=split(":",$str);
	$cmd="cccccc$num";
	$cmd = '"'.$cmd.'"';
	$cmd ="'"."EXEC TSC NATIVE CMD=$cmd"."'";
	$cmd ="OSST_ciaxTSCcommand $timeout $cmd";
    }else{
	$cmd="OSST_ciax$str";
    }
    $this->{rver}->statprt("EXEC:$cmd");
    `$cmd`;
    my $err=$?;
    $this->{err}=$err/256;
    $this->{rver}->statprt("ERRCODE:$this->{err}");
    return if($err != 0);
    sleep 1;
}

sub getstat($){
    my($this)=@_;
    my $cmd=$this->{ucmd};
    my $stat=sprintf("%02X",$this->{err});
    $this->{rver}->statprt("UPDATE:$cmd");
    my @st=`$cmd`;
    my @bts=@{$this->{bts}};
    foreach (@st){
	chomp;
	my $byte=shift @bts;
	$stat.=substr($_,0,$byte);
    }    
    $this->{rver}->statprt("STOUT:$stat");
    return $stat;
}
1;
