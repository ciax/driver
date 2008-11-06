#!/usr/bin/perl -wc
# Copyright (c) 1997-2006, Koji Omata, All right reserved
# Update History
# 2007/8/22 Debug: add resetTimeout in resetexe and resetisu
# 2007/2/3 Prevent upd command duplication
# 2006/12/21 Reorganization
# 2006/12/19 Add setExe setIsu
# 2006/11/6 JSON send by udp
# 2006/10/30 JSON file write every update
# 2006/10/30 DB_stat includes timestamp
# 2006/10/24 UPD interval is 60s or 300s
# 2006/6/10 Debug
# 2006/6/1 Timeout module is separated
# 2006/5/30 Handling any command timeout
# 2006/4/6 Handling invalid updtime in isitvl
# 2006/3/31 Debug/isitvl
# 2006/3/25 Split server into recvcmd/dispatch/sendstat
# 2006/3/21 Bugfix: Identify 0 with Null Bug (ZN Bug)
# 2006/3/9 stat:sym cmd created
# 2006/2/9 CTL_shared::driver needs CTL_shared::end
# 2005/11/30 Add timestamp in csv/raw
# 2005/11/18 Debug about "stop" command
# 2005/10/19 Check mode
# 2005/9/27 SQL function
# 2005/6/13 (add rec/stop, add mode to rec/cmd)
# 2005/4/28 (add:DB_cmd-> initdev para)
# 2005/3/21 (add stat:raw)
# 2006/1/30 (csv,raw comes by array)
package SVR_dev;
use strict;
use SVR_shared;
@SVR_dev::ISA=qw(SVR_shared);
use DB_mode;
use DB_cmd;
use DB_stat;
use MTN_log;
use CTL_shared;
use SYS_sql;
use SYS_timer;

#################### Public ########################
### UDP response: mode=???,a=??,b=?? if $para is true
sub new($$){
    my($pkg,$mode)=@_;
    my $rmod=new DB_mode($mode,"[mode]");
    $rmod->ishost(1);
    my %mpar=$rmod->getmpar;
    $mpar{rcmd}=new CTL_shared(%mpar);
    my $this=new SVR_shared(%mpar);
    $mpar{server}=1;
    $this->{sdb}=new DB_stat($mode);
    $this->{msl}=new SYS_shmem(%mpar);
    my $rcmd=new DB_cmd($mpar{mode});
    $this->{msl}->initdev($rcmd->getdb("cmdstr","upd"));
    $this->{rlog}=new MTN_log($mode);
    $this->{sql}=new SYS_sql($mpar{mode});
    $this->{json}=new SYS_file("json-$mode.txt","s");
    $this->{updint}=$this->{updint}||60;
    $this->{itm}=new SYS_timer("[$mode] [int] autoupdate",$this->{updint});
    $this->{etm}=new SYS_timer("[$mode] [exe]",600);
    $this->{utm}=new SYS_timer("[$mode] [upd]",30);
    bless $this;
}

sub server($){
    my($this)=@_;
    return if($this->SUPER::server($this->{port}));
    $this->{rver}->statprt("UPDEVERY:$this->{updint}");
    $this->serverReset;
    while(1){
	my $data=$this->{udp}->rcv(2);
	$this->{rver}->statprt("RECIEVE [$data]",1) if($data);
	$this->recvcmd($data);
	$this->dispatch;
	$this->childwait;
	$this->sendstat($data);
    }
    return 1;
}

#######################  Private ######################
#### Handle Flags ####
sub setisu($){
    my ($this)=@_;
    $this->{msl}->putshm("isu",1);
    $this->{utm}->setTimeout;
}

sub setexe($){
    my ($this)=@_;
    $this->{msl}->putshm("exe",1);
    $this->{etm}->setTimeout;
}

sub resetisu($){
    my ($this)=@_;
    $this->{upid}=0;
    $this->{msl}->putshm("isu",0);
    $this->{utm}->resetTimeout;
}

sub resetexe($){
    my ($this)=@_;
    $this->{epid}=0;
    $this->{msl}->putshm("exe",0);
    $this->{etm}->resetTimeout;
}

sub isexe($){
    my ($this)=@_;
    return 1 if($this->{epid});
    return 1 if($this->{msl}->getshm("exe"));
}

sub isisu($){
    my ($this)=@_;
    return 1 if($this->{upid});
    return 1 if($this->{msl}->getshm("isu"));
}

sub serverReset($){
    my ($this)=@_;
    @{$this->{cmdstr}}=();
    $this->resetexe;
    $this->resetisu;
    $this->{rver}->statprt("Server Reset");
}

###############  Server Process ##############
sub recvcmd($$){
    my ($this,$data)=@_;
    return 1 if($data =~ /^stat/ or $data eq "");
    if($data eq "reset"){
	$this->serverReset;
    }elsif($data eq "stop"){
	@{$this->{cmdstr}}=();
	if($this->{epid}){
	    kill(2,$this->{epid});
	    $this->resetexe;
	    $this->{rlog}->rec("$this->{mode}:stop",1);
	}
    }elsif($data eq "upd"){
	push @{$this->{cmdstr}},$data unless(grep(/upd/,@{$this->{cmdstr}}));
    }elsif($data){
	if($this->{rcmd}{rcmd}->setkey($data)){
	    push @{$this->{cmdstr}},$data;
	}else{
	    $this->{msl}->putshm("cme","S");
	    return;
	}
    }
    return 1;
}

sub sendstat($$){
    my ($this,$data)=@_;
    return unless($data);
    $this->updstat;
    my $stat='';
    if($data=~ /stat:/){
	if($data=~/csv/){
	    $stat=join(",",$this->{sdb}->sym);
	}elsif($data=~/raw/){
	    $stat=join(",",$this->{sdb}->raw);
	}elsif($data=~/sym/){
	    $stat=join("\n",$this->{sdb}->sym);
	}elsif($data=~/json/){
	    $stat=$this->{sdb}->json;
	}
    }else{
	$stat=$this->{sdb}->getbody;
    }
    $this->{rver}->statprt("SENDSTAT:$stat");
    $this->{udp}->snd($stat);
    return 1;
}

## $SIG{CHLD} handle routine
sub childwait($){
    my ($this)=@_;
    my $pid=$this->cwait;
    # EPID
    if($this->{epid} eq $pid){
	$this->resetexe;
	$this->{rver}->statprt("Child $pid(EXE) EXIT");
    }elsif($this->{etm}->isTimeout){
	$this->resetexe;
	$this->{rver}->statprt("Child (EXE) Timeout");
    }
    # UPID
    if($pid>0){
	$this->resetisu;
	$this->{rver}->statprt("Child $pid(UPD) EXIT");
	$this->updlog;
    }elsif($this->{utm}->isTimeout){
	$this->resetisu;
	$this->{rver}->statprt("Child (UPD) Timeout");
    }
    return 1;
}

# Update Status
sub updstat($){
    my ($this)=@_;
    my ($stat)=$this->{msl}->getshm("body");
    my ($date)=$this->{msl}->getshm("time");
    $this->{sdb}->setdate($date);
    $this->{sdb}->setdef($stat);
    return 1;
}

sub updlog($){
    my ($this)=@_;
    my ($stat)=$this->{msl}->getshm("body");
    $this->{sdb}->setdef($stat);
    $this->{json}->wri($this->{sdb}->json);
    $this->{rlog}->rec($stat);
    $this->{sql}->rec($stat);
    return 1;
}

## Process Dispatcher
sub dispatch($){
    my ($this)=@_;
    $this->{rver}->statprt("CMDQUEUE:".join(" ",@{$this->{cmdstr}}),2);
    return if($this->isisu);
    my $cmd=shift @{$this->{cmdstr}};
    if($cmd =~ /upd/){
	$this->issue("upd");
    }elsif($cmd eq ""){
	$this->issue("upd") if($this->{itm}->checkTimer);
    }elsif($this->isexe){
	unshift @{$this->{cmdstr}},$cmd;
	return;
    }else{
	$this->execmd($cmd);
	$this->{rlog}->rec("$this->{mode}:$cmd",1);
    }
    return 1;
}

# Sub Process
sub execmd($$){
    my ($this,$cmd)=@_;
    return if($cmd eq "");
    $this->{rver}->statprt("ACTION:$cmd");
    $this->setisu;
    $this->setexe;
    my $pid=$this->cfork("$this->{name}-exe");
    if($pid){
	$this->{epid}=$pid;
	$this->{rver}->statprt("Child $pid(EXE) START");
    }else{
	$this->{msl}{root}=0;
	$this->{rcmd}->driver($cmd);
	$this->{rcmd}->end;
	$this->cexit;
    }
    return 1;
}

sub issue($$){
    my ($this,$cmd)=@_;
    return if($cmd eq "");
    $this->{rver}->statprt("ISSUED:$cmd");
    $this->setisu;
    my $pid=$this->cfork("$this->{name}-isu");
    if($pid){
	$this->{upid}=$pid;
	$this->{rver}->statprt("Child $pid(UPD) START");
    }else{
	$this->{msl}{root}=0;
	$this->{rcmd}->driver($cmd);
	$this->{rcmd}->end;
	$this->cexit;
    }
    return 1;
}

# $SIG{TERM} Handle routine
sub svstop($){
    my ($this)=@_;
    $this->{rlog}->end;
    $this->{msl}->endshm;
    $this->SUPER::svstop;
}
1;
