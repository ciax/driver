#!/usr/bin/perl -wc
# Command dispatcher
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2004/6/17
package FSP_nt;
use DB_cmd;
use FSP_fspc;
use MTN_log;
#use SYS_sql;

$interval_normal=3600;
$interval_exec=20;
$interval_reset=3600;

sub new($%){
    my($pkg,%modes)=@_;
    my $mode=$modes{mode};
    my $this={mode=>$mode};
    $this->{rlog}=new MTN_log($mode);
#    $this->{rsql}=new SYS_sql($mode);
    $this->{rcom}=new FSP_fspc($mode);
    $this->{rcmd}=new DB_cmd($mode,$modes{usage});
    bless $this;
}

sub init($$){
    my($this,$initcmd)=@_;
    $this->{cexe}="001";
    ($this->{exec},$this->{isu},$this->{sflg},$this->{cerr})=(0,0,0,"_");
    @{$this->{cmd}}=($initcmd) if($initcmd);
    $this->{rcom}->init;
    $this->isitvl($interval_normal);
}

sub operation($$){
    my($this,$cmd)=@_;
    $this->regcmd($cmd);
    $this->putcmd;
    $this->getstat;
}

sub dispatch($){
    my($this)=@_;
    $this->autoupd;
    $this->cdpwstat;
}

# Command recieve from client
sub regcmd($$){
    my($this,$data)=@_;
    return unless($data);
    return if($data eq "stat");
    if($data eq "reset"){
	$this->init("upd");
	return;
    }
    @{$this->{cmd}}=() if($data =~ /(stop|reset)/);
    push @{$this->{cmd}},$data;
}

############ Internal Modules #############
sub autoupd($){
    my($this)=@_;
    return if($this->{isu} == 1);
    return if(scalar @{$this->{cmd}} > 0);
    my $int=$interval_normal;
    $int=$interval_exec if($this->{sflg} == 2);
    $int=$interval_reset if($this->{alarm});
    return unless($this->isitvl($int));
    @{$this->{cmd}}=($this->{alarm}==1)?("ntres"):("upd");
    $this->{updcnt}=0;
}

# Command issue to station
sub putcmd($){
    my($this)=@_;
    return if($this->{isu});
    my $cmd=shift @{$this->{cmd}};
    return if(!$cmd);
    my $data=$this->{rcmd}->getdb("cmdstr",$cmd);
    if($this->{rcom}->setcmd($data)){
	$this->{isu}=1;
	$this->{exec}=1 if($data =~ /^setmove/);
	($this->{cexe},$this->{sflg})=("101",1) if($cmd =~ /run/);
	($this->{cexe},$this->{sflg})=("011",0) if($cmd =~ /lft/);
	$this->{rlog}->rec($cmd,1);
    }else{
	$this->{cerr}="E";
    }
}

# Status get from station
sub cdpwstat($){
    my($this)=@_;
    ($strb,$this->{resp})=$this->{rcom}->getstat;
    $this->{resp}=~ s/ +$//g;
    $this->{resp}=~ s/ {5}01001000$//g if($this->{mode} =~ /nso/);
    $this->{resp}.=$this->{cexe} if($this->{mode} =~ /[nh]ct/);
    if($strb){
	my ($header,$local)=unpack("A20A*",$this->{resp});
	$this->{alarm}=($local=~/^0000/)?1:0;
	my $remote=substr($local,3,1);
	$this->{cerr}="_";
	# Command Issued
	$this->{isu}=0 unless($header =~ /step/);
	# Cart (run,jack,remote) flags for MLP3
	$this->{cexe}="001" if($header =~ /end/);
	$this->{cexe}="001" if($this->{cexe} eq "000");
	$this->{cexe}="000" if($header =~ /err/ or $this->{alarm} or !$remote);
	# Executing flag set/reset
	$this->{exec}=1 if($header =~ /(setmove|start|step)/);
	$this->{exec}=0 if($header =~ /(err|end|reset)/ or $this->{alarm});
	# Auto update flag (1=Ready 2=Auto)
	$this->{sflg}=0 if($header =~ /(step|err|end)/ or $this->{alarm});
	$this->{sflg}=1 if($header =~ /stop/ and $this->{sflg}==2);
	$this->{sflg}=2 if($header =~ /start/ and $this->{sflg}==1);
	$this->autocommand;
    }
    if($strb){
	my $stat=$this->getstat;
	$this->{rlog}->rec($stat,2); 
#	$this->{rsql}->rec($stat); 
    }
}

sub getstat($){
    my($this)=@_;
    my $msg=pack("AAA",$this->{exec},$this->{isu},$this->{cerr});
    my $ntstat=pack("A5A*","%$this->{mode}_",$msg.$this->{resp});
    return $ntstat;
}

# Command dispatching
sub autocommand($){
    my($this)=@_;
    my ($header,$local)=unpack("A20A*",$this->{resp});
    my $setadr=($this->{mode}=~/[nh]ct/ and $local=~/^10010000/);
    @{$this->{cmd}}=() if($header =~ /(stop|err|end)/);
    @{$this->{cmd}}=("start") if($header =~ /(setmove|step)/);
    @{$this->{cmd}}=("upd") if($header =~ /setpara/);
    if($header =~ /status/){
	if($this->{alarm}){
	    @{$this->{cmd}}=("ntres"); 
	}elsif($setadr and $this->{updcnt} < 3){
	    ($this->{sflg},$this->{exec})=(0,0);
	    $this->{updcnt}++;
	    @{$this->{cmd}}=("setadr");
	}
    }
}

## Interval timer
sub isitvl($$){
    my($this,$int)=@_;
    return unless($int);
    if(time - $this->{itime} > $int){
	$this->{itime}=time;
	return 1;
    }
    return;
}
1;

## $SIG{TERM} Handle routine
sub svstop($){
    my ($this)=@_;
    $this->{rlog}->end;
    #$this->SUPER::svstop;
}
1;

