#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update: 2007/2/3 Remove output from cfork, Add warning to cexec
# 2006/12/21 Add function: daemon cexec cwait
# 2006/6/2 Not die by failed Kill
# 2005/10/25 Warn handling
# 2003/12/9
package SVR_shared;
use strict;
use POSIX ":sys_wait_h";
use POSIX 'setsid';
use SYS_file;
use UDP_server;

sub new($%){
    my($pkg,%par)=@_;
    my $name=$0;
    $name=~ s/.*\///;
    my $this={%par};
    $this->{name}=$name;
    $this->{rver}=new MTN_ver("SRVCMD($name)%6","exe");
    $this->{rpid}=new SYS_file("$this->{name}.pid","r");
    bless $this;
    $this->ckill;
    return $this;
}
 
sub server($$){
    my ($this,$port)=@_;
    $this->{udp}=new UDP_server($port,$this->{name}) if($port);
    $this->{rver}->warning("[$this->{name}] START PID=$$%2");
    $SIG{TERM}=sub{$this->svstop};
    $SIG{INT}=sub{$this->svstop};
    return;
}

sub daemon($$){
    my ($this,$output)=@_;
    chdir "/";
    setsid;
    $SIG{HUP}='IGNORE';
    $this->cexit if($this->cfork);
    $this->output($output);
}

sub ckill($){
    my ($this)=@_;
    my @pids=$this->{rpid}->red;
    $this->{rpid}->clr;
    foreach(@pids){
	next unless($_>0);
	kill(15,$_) or next;
	$this->{rver}->warning("[$this->{name}] TERMINATED PID=$_%2");
    }
    $this->{rpid}->wri($$);
    sleep 2;
}

sub cfork($$){
    my ($this,$name)=@_;
    my $pid=fork;
    return $pid if($pid);
    $0=$name if($name);
    $this->{rver}->statprt("Child process forked");
    $this->{rpid}->append($$);
    return;
}

sub cexec($$$){
    my ($this,$cmd,$output)=@_;
    my $pid=fork;
    return $pid if($pid);
    $cmd=~/^.*\//;
    $this->{rver}->warning("Loading $' ($$)");
    $this->output($output);
    exec($cmd);
}

sub cexit($){
    my ($this)=@_;
    $this->{rpid}->rmline($$);
    $this->{rver}->statprt("Child process terminated");
    exit;
}

sub cwait($){
    my ($this)=@_;
    my $pid=waitpid(-1,WNOHANG);
    return $pid if($pid>0);
    return;
}

sub output($$){
    my ($this,$output)=@_;
    if($output){
	$output="$ENV{DRVVAR}/run/$output";
    }else{
	$output="/dev/null";
    } 
    open(STDERR,">>$output");
    open(STDOUT,">/dev/null");
    open(STDIN,"</dev/null");
}

sub svstop($){
    my ($this)=@_;
    $SIG{TERM}=undef;
    $SIG{INT}=undef;
    $this->{rpid}->rmline($$);
    $this->{rver}->warning("[$this->{name}] Server Terminated!%C");
    exit 1;
}
1;
