#!/usr/bin/perl -wc
# Copyright (c) 1997-2005, Koji Omata, All right reserved
# Last update 2007/2/4 While loop for waiting cmd termination debug.
# 2005/10/8 !(NEG flag) -> SKP
# 2005/9/28: Add exit code
# 2005/9/23: Add Skip option at Proceed query
# 2005/6/15: Quely by ilk -> cmd type "act"
# 2005/6/7: Add Retry option at Interlock NG
# 2005/6/3: read cdb by $ENV{PROJECT}
# 2005/5/16: Force/Skip selection at Interlock NG
# 2003/12/9
package EXE_mcr;
use strict;
use DB_mode;
use CLI_stat;
use EXE_ilk;
use CLI_cmd;
use MTN_log;

# $exe-> 0:Test Mode 1:Exec Mode 2:Nonstop Mode
sub new($$$){
    my($pkg,$exe,$loghead)=@_;
    my $this={test=>(!$exe),nst=>($exe>1),err=>""};
    my $usage="[-e] [cmd1] [cmd2]..[cmdN] ($ENV{PROJECT})";
    $this->{rmod}=new DB_mode("mcr",$usage);
    my %mpar=$this->{rmod}->getmpar;
    $this->{port}=$mpar{port};
    $this->{rmcr}=new DB_shared("cdb_{000,mcr}.txt",$this->{rmod}{usage});
    $this->{rst}=new CLI_stat;
    $this->{rilk}=new EXE_ilk($this->{rst});
    $this->{rlog}=new MTN_log($loghead,$this->{test});
    $this->{rprt}=new SYS_stdio;
    $this->{rmcv}=new DB_shared("db_mcv-$ENV{PROJECT}.txt");
    $this->{line}=0;
    bless $this;
}

sub setmcr($@){
    my($this,@cmds)=@_;
    $this->{rmcr}->setkey unless(scalar @cmds);
    $this->{rmcr}->setkey($_) foreach(@cmds);
    my $str="EXEC";
    $str="TEST" if($this->{test});
    $str="NONSTOP" if($this->{nst});
    $this->{col}=0;
    $this->prt("### MCR $str MODE! ###");
    foreach(@cmds){
	$this->setcmd("mcr:$_");
	if($this->{err}){	
	    $this->prt("Error!%1");
	    last;
	}
    }
    $this->{col}=0;
    $this->prt("### MCREND ###");
    return $this->{err};
}

sub setcmd($$){
    my($this,$str)=@_;
    $this->{col}++;
    foreach(split(/ /,$str)){
	my $neg=(s/^!//)?1:0;
	my ($dmode,$dcmd,$nowait)=split(/:/);
	$dcmd=$this->convert($dcmd);
	$this->{rmod}->setmode($dmode);
	my $lcmd=$this->chkcmd($dmode,$dcmd);
	if($dmode =~ /msg/){
	    $this->prt("  -> Done?[Press Key]",1);
	    $this->input;
	    next;
	}
	if($lcmd){
	    my $iflg=$this->chkilk($dmode,$dcmd,$neg);
	    if($iflg eq "EXE"){
		if($dmode =~ /mcr/){
		    $this->setcmd($lcmd);
		    last if($this->{err});
		    next;
		}
		$this->{col}++;
		if($this->{test}){
		    $this->prt("Dry-Run!");
		}else{
		    $this->execmd($dcmd,$nowait);
		}
		$this->{col}--;
		last if($this->{err});
	    }elsif($iflg eq "NG"){
		$this->{err}=1;
		last;
	    }
	}
    }
    $this->{col}--;
}

sub chkcmd($$$){
    my($this,$mode,$cmd)=@_;
    if(not exists $this->{rcmd}{$mode}){
	$this->{rcmd}{$mode}=new DB_cmd($mode,"$mode");
    }    
    return unless($this->{rcmd}{$mode}->setkey($cmd));
    my $caption=$this->{rcmd}{$mode}->getdb("caption");
    $caption=uc($mode).":".$caption;
    $caption.="%5" if($mode =~ /msg/);
    $this->prt($caption);
    return $this->{rcmd}{$mode}->getdb("cmdstr");
}

sub chkilk($$$$){
    my($this,$mode,$cmd,$neg)=@_;
    while(1){
	my ($flg,@rem)=$this->{rilk}->getdb($mode,$cmd);
	$this->prt($_) foreach(@rem);
	my $type=$this->{rcmd}{$mode}->getdb("type");
	if($neg){
	    $this->prt("Temporaly skip!%2");
	    return "SKP";
	}elsif($flg =~ /EXE/ and $type=~/act/){
	    return $this->query($mode);
	}elsif($flg =~ /(SKP|EXE)/){
	    return $flg
	}elsif($flg =~ /NG/){
	    $flg=$this->revival($mode);
	    return $flg if($flg!~/RTY/);
	}
    }
}

sub execmd($$$){
    my($this,$cmd,$nowait)=@_;
    my $dvcl=new CLI_cmd($this->{rmod}->getmpar);
    if(! $dvcl->isend){
	$this->prt("Waiting for command termination!%3");
	while(! $dvcl->isend){select(undef,undef,undef,0.5);}
	sleep 1;
    }
    $this->prt("Execute($cmd)!%2");
    my $stat=$dvcl->setcmd($cmd,!$nowait);
    $this->prt($stat);
    $this->{err}=2 if($stat =~ /err/ or substr($stat,4,4) =~ /E/);
}

sub query($$){
    my($this,$mode)=@_;
    return "EXE" if($mode =~ /mcr/ or $this->{nst});
    while(1){
	my $str="  -> Proceed?[Y/S/Q]";
	$this->prt($str);
	my $inp=$this->input;
	return "EXE" if($inp =~ /[Yy]/);
	return "SKP" if($inp =~ /[Ss]/);
	return "NG" if($inp =~ /[Qq]/);
    }
}

sub revival($$){
    my($this,$mode)=@_;
    return "NG" if($this->{nst});
    while(1){
	$this->prt(" -> Retry/Force/Skip/Quit?[R/F/S/Q]");
	my $inp=$this->input;
	return "RTY" if($inp =~ /[Rr]/);
	return "EXE" if($inp =~ /[Ff]/);
	return "SKP" if($inp =~ /[Ss]/);
	return "NG" if($inp =~ /[Qq]/);
    }
}

sub convert($$){
    my($this,$cmd)=@_;
    if($cmd =~ /%/){
	foreach ($this->{rmcv}->getkeys){
	    next if($cmd !~ /%$_/);
	    my $st=$this->{rmcv}->getdb("stat",$_);
	    my ($sym)=split(":",$this->{rst}->symbol($st));
	    my $opt=$this->{rmcv}->getdb("option",$_);
	    foreach(split(/ /,$opt)){
		next if(!/=/);
		my ($s,$o)=split(/=/);
		$sym=$o if($sym=~/$s/);
	    }
	    $sym=lc($sym);
	    $cmd =~ s/%$_/$sym/g;
	}
    }
    return $cmd;
}

# -------- ABSTRACT CLASS ---------

sub input($$){
    my($this,$timeout)=@_;
    my $bits=undef;
    select(STDIN);$|=1;select(STDOUT);
    vec($bits,fileno(STDIN),1)=1;
    select($bits,undef,undef,$timeout);
    if(vec($bits,fileno(STDIN),1)){
	my $in=<STDIN>;
	return $in;
    }
}

sub prt($$$){
    my($this,$str,$nocr)=@_;
    return unless($str);
    $this->{line}++;
    my $pre="[".$this->{line}."]"." " x ($this->{col}*2);
    print $pre.$this->{rprt}->color($str);
    print "\n" unless($str =~ /\?/ or $nocr);
    $this->{rlog}->rec($pre.$str) unless($this->{test});
}
1;
