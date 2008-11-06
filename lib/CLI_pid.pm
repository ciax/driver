#!/usr/bin/perl -wc
# Last update 2006/6/20

# Parameters from File
# sp = Set Point
# cv = Current value
# ti = Time interval
# kp,ki,kd = PID Control parameter(gain)
# ui = Unit of Input value (Includes Setpoint)
# uo = Unit of Output value
# ov = Output value
# ov:max = Maximum Output value
# ov:min = Minimum Output value
# sv = Servo mode

package CLI_pid;
use strict;
use VAR_static;
use VAR_queue;

sub new($$$){
    my($pkg,$id)=@_;
    my $this ={id=>$id,level=>0};
    $this->{par}=new VAR_static($id);
    $this->{err}=new VAR_queue($id."_err",4);
    $this->{st}=new VAR_queue($id."_st",4);
    bless $this;
}

sub setpoint($$){
    my($this,$sp)=@_;
    $this->{par}->set("sp",$sp);
    return 1;
}

sub ovchk($){
    my($this)=@_;
    my $ov=$this->{par}->get("ov");
    my $val=($ov==0)?0:$ov;
    ($ov,$this->{level})=$this->{par}->chkval("ov",$ov);
    $this->{par}->set("ov",$ov);
    return $val
}

sub svoff($){
    my($this)=@_;
    return $this->{par}->set("sv",0);
}

sub ctlrate($$){
    my($this,$cv)=@_;
    my @stat=$this->{st}->queue($cv);
    return if(scalar @stat < 3);
    return $this->ctlconst($stat[0]-$stat[1]);
}

sub ctlconst($$){
    my($this,$cv)=@_;
    my @err=$this->{err}->queue($this->{par}->get("sp")-$cv);
    return if(scalar @err < 3);
    my $p=$this->{par}->get("kp")*($err[0]-$err[1]);
    my $i=$this->{par}->get("ki")*$err[0];
    my $d=$this->{par}->get("kd")*($err[0]+$err[2]-$err[1]*2);
    my $ov=$this->{par}->get("ov")+$p+$i+$d;
    ($ov,$this->{level})=$this->{par}->chkval("ov",$ov);
    $this->{par}->set("cv",$cv);
    return unless($this->{par}->get("sv") == 1);
    $this->{par}->set("ov",$ov);
    return $ov;
}

sub prtstat($){
    my($this)=@_;
    my %lev=(1=>"max",-1=>"min",0=>"normal");
    my %drv=(1=>"ON",0=>"OFF");
    my %par=$this->{par}->gethash;
    my @err=$this->{err}->get;
    my @str=("ID=$this->{id}, Servo=$drv{$par{sv}}");
    push @str,"\tSetPoint=$par{sp}$par{ui}, Current Value=$par{cv}$par{ui}";
    push @str,"\tPARAM [ P=$par{kp}, I=$par{ki}, D=$par{kd} ]";
    push @str,"\tERR=(@err)" if(scalar @err);
    push @str,"\tControl Value=$par{ov}$par{uo}, Level=$lev{$this->{level}}";
    return @str;
}

sub getstat($$$){
    my ($this,$sym,$data)=@_;
    my %st=$this->{par}->a2h(split("\n",$data));
#print "$this->{id}=$st{time}\n";
    $this->{"last"}=$st{"time"};
    return $st{$sym};
}

sub isupd($){
    my ($this)=@_;
    return 0 if($this->{"last"} eq $this->{prev});
    $this->{prev}=$this->{"last"};
    return 1;
}
1;
