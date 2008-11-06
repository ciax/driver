#!/usr/bin/perl -wc
# Verbose status routine for Send and Receive
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Dependency level 1
# Last update 2007/2/3 VER Env is printed at Start
# 2006/6/29 Using SYS_date
# 2006/2/9 VER format [mode:id/id/id/...]
# 2006/2/6 Exit if count_stop w/ errstr
# 2005/10/25 Add warning function and write to *.err
# 2005/10/3: Add die function to count_stop
# 2004/12/10
package MTN_ver;
use strict;
use SYS_stdio;
use SYS_date;

sub new($$$){
    my($pkg,$name,$id)=@_;
    $id=lc($id);
    my $this ={count=>0,id=>$id};
    $this->{rprt}=new SYS_stdio;
    $this->{name}=$this->{rprt}->color("($id)$name");
    my $env=lc($ENV{VER});
    unless($env =~ /:/ and $env !~ /$ENV{MODE}/){
	$this->{ver}=($env =~ /($id|all)/);
    }
    $this->{test}=($env =~ /test/);
    bless $this;
    $this->_errout("VER=$ENV{VER}") if($this->{ver});
    return $this;
}

############# External subroutines ###############
sub warning($$){
    my($this,$str)=@_;
    $str=$this->{rprt}->color($str);
    $this->_errout($str);
}

sub statprt($$$){
    my($this,$str,$id)=@_;
    $id="A0" unless($id);
    if($this->{str}{$id} eq $str){
	$this->istimeout if($this->{ver});
    }else{
	$this->{str}{$id}=$str;
	$this->clrtimeout;
	$str=$this->{rprt}->visible($str);
	$this->_errout("$this->{name}/$str") if($this->{ver});
    }
}

sub datprt($$@){
    my($this,$fname,@data)=@_;
    return unless($this->{ver});
    chomp @data;
    $this->_errout("$fname:\n\t[".join("/",@data)."]");
}

sub istest($$){
    my($this,$str)=@_;
    if($this->{test} and $str){
	$str=$this->{rprt}->visible($str);
	$this->_errout("$this->{name}/$str"); 
    }
    $this->{test};
}

############# Timeout subroutines ###############
sub istimeout($){
    my($this)=@_;
    if($this->{count}++ >50000){
	$this->clrtimeout;
	$this->_errout("$this->{name}/.... TimeOUT!");
    }
}

sub clrtimeout($){
    my($this)=@_;
    $this->{count}=0;
}

sub count_start($$){
    my ($this,$timeout)=@_;
    return unless($timeout);
    my $ppid=$$;
    $this->_errout("$this->{name}/Counting start!") if($this->{ver});
    my @sig=($SIG{INT},$SIG{TERM});
    ($SIG{INT},$SIG{TERM})=();
    $this->{pid}=fork;
    $timeout+=time;
    while(!$this->{pid}){
	my $count=$timeout-time;
	if($count<0){
	    $this->_errout("$this->{name}/Timeout for OPEN!") if($this->{ver});
	    kill(15,$ppid);
	    exit;
	}
	print STDERR "$this->{name} $count  \r" if($this->{ver});
	sleep 1;
    }
    ($SIG{INT},$SIG{TERM})=@sig;
}

sub count_stop($$){
    my ($this,$str)=@_;
    kill(15,$this->{pid}) if($this->{pid});
    if($str){
	$this->_errout($str);
	exit 1;
    }
    $this->_errout("$this->{name}/Counting finished!") if($this->{ver});
}

sub _errout($$){
    my($this,$str)=@_;
    warn(timestamp." [".$ENV{MODE}."]  $str\n");
}
1;
