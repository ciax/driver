#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2007/2/7: condition prefix "!" is ignored
# 2005/6/15: delete QRY result
# 2003/2/27
package EXE_ilk;
use strict;
use DB_shared;

sub new($$$){
    my($pkg,$rst,$usage)=@_;
    my $this={rst=>$rst,usage=>$usage};
    bless $this;
}

# getdb(command) => NG:Exit SKP:Skip EXE:OK
sub getdb($$$){
    my($this,$mode,$cmd)=@_;
    $this->{cmode}=$mode;
    if(not exists $this->{idb}{$mode}){
	$this->{idb}{$mode}=new DB_shared("idb_{000,$mode}*.txt",$this->{usage});
    }
    my $c=$this->{idb}{$mode}->setkey($cmd);
    exit unless($cmd);
    my $cp=($cmd eq $c)? $cmd : "$cmd -> $c";
    my $caption="[$mode:$cp]%6";
    return("EXE",$caption,"No description in IDB%1") unless($c);
    my $skp=$this->{idb}{$mode}->getdb("skp");
    if($skp){
	my ($skpflg,@skpstr)=$this->_condition_and($skp);
	return("SKP",$caption,@skpstr,"=>SKIP%2") if($skpflg eq "OK");
    }
    my $alws=$this->{idb}{$mode}->getdb("alws");
    return("EXE",$caption) if($alws =~ /^\*/);
    if($alws){
	my ($alwflg,@allow)=$this->_condition_and($alws);
	return("EXE",$caption,@allow,"=>EXECUTABLE%2") if($alwflg eq "OK");
	return("NG",$caption,@allow,"=>CANCEL%1") if($alwflg eq "NG");
    }   
    return("EXE",$caption);
}

############## Internal routine ############
sub _condition_and($$){
    my($this,$cond)=@_;
    my ($tf,@rem)=("OK");
    if($cond){
	foreach (split('&',$cond)){
	    next if(/^!/);
	    my ($flg,$def,$val)=$this->_chkstat($_);
	    if($flg){
		push @rem,"OK <$def>%2"; 	
	    }else{
		$tf="NG";
		push @rem,"NG <$def but $val>%1";
	    }
	}
    }
    return ($tf,@rem);
}

sub _chkstat($$){
    my ($this,$cond)=@_;
    return 0 unless($cond);
    my $comp="";
    my ($key,$def)=split(/[=!~^]/,$cond);
    $comp="=~" if($cond =~ /[=~]/);
    $comp="!~" if($cond =~ /[!\^]/);
    ($this->{cmode},$key)=split(':',$key) if($key =~ /:/);
    my $stat=$this->{rst}->symbol("$this->{cmode}:$key");
    my ($val,$mode,$caption)=split(':',$stat);
    $caption="$mode:$caption$comp$def";
    return (1,$caption,$val) if($val =~ /$def/ and $cond =~ /[=~]/);
    return (1,$caption,$val) if($val !~ /$def/ and $cond =~ /[!\^]/);
    return (0,$caption,$val);
}
1;
