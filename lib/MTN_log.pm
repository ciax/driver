#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Dependency level 2
# Last update: 2006/10/24 Set timer (logged every stat changes or once a 1hr)
# 2006/6/29 Retract Function Add
# 2006/6/29 Using SYS_date
# 2006/4/7 Log skip if "upd" and "stat" included in cmd
# 2006/3/22 Logfilename is XXX-######.log
# 2006/3/22 Use LOG environment LOG=SKIP:SQL:NO
# 2006/3/21 Delete Log skipping (Skip if value is same as previous)
# 2005/6/8: Add void function
# 2005/5/16: Add Initial record, deleting home link
# 2004/6/15
package MTN_log;
use strict;
use SYS_file;
use SYS_date;
use SYS_timer;

# MTN_log file open
sub new($$$){
    my($pkg,$filehead,$void)=@_;
    my $this={link=>"$ENV{HOME}/$filehead.log",rec=>0,void=>$void};
    bless $this;
    return if($void);
    my ($date,$time)=split("-",timestamp);
    $this->{lf}=new SYS_file("$filehead-$date","l");
    unlink $this->{link};
    symlink $this->{lf}{path},$this->{link};
    $this->{timer}=new SYS_timer("Hourly",3600);
    return $this;
}

sub recini($){
    my ($this)=@_;
    return 1 if($this->{rec});
    $this->{rec}=1;
    $this->rec("#### logging start ####");
}

sub rec($$$){
    my ($this,$str,$id)=@_;
    return if($ENV{LOG}=~/NO/ or $this->{void});
    $this->recini;
    $id= $id || 0;
    my $force=$this->{timer}->checkTimer;
    return if($this->{$id} eq $str and ! $force);
    return if($str =~ /^(upd|stat)/);
    $this->{$id}=$str;
    $this->{lf}->append(timestamp." $str");
}

sub end($){
    my ($this)=@_;
    return if($ENV{LOG}=~/NO/ or $this->{void});
    my $path=$this->{lf}{path};
    my ($date,$time)=split("-",timestamp);
    return if($path =~ /$date/);
    $path=~ s/\.log/-$date\.log/;
    rename $this->{lf}{path},$path;
    unlink $this->{link};
}
1;
