#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/10/30 Bugfix getwait must give number include 0
# 2006/10/25 Cmd Convert '\r','\n'
# 2006/10/25 Stat Convert ESC-CHAR -> '\'
# 2006/8/3 Debug for sum
# 2005/10/15 VER description update
# 2005/10/3 Nodata handling
# 2004/12/9 DEBUG VER="str"
package DB_device;
use strict;
use DB_shared;
use MTN_ver;
@DB_device::ISA=qw(DB_shared);

sub new($$$){
    my($pkg,$devtype,$usage)=@_;
    my $this=new DB_shared("db_device*.txt",$usage);
    $this->{rver}=new MTN_ver("CONV%B","str");
    bless $this;
    $this->{key}=$this->setkey($devtype);
    return $this;
}

############### TTY PARAMATER SETTING ##############
sub getsttypar($){
    my($this)=@_;
    my $protocol=$this->getdb("protocol");
    return unless($protocol);
    my ($speed,$chr,$par,$stop,$flow)=split(/:/,$protocol);
    my $str="speed $speed clocal";
    $str.=" pass8" if($chr eq "8");
    $str.=" evenp" if($par eq "E");
    $str.=" oddp" if($par eq "O");
    $str.=" cstopb" if($stop eq "2");
    $str.=" crtscts" if($flow eq "CTS");
    my ($pre,$del)=split(/:/,$this->getdb("affix"));
    if($del){
	$str.=" sane";
	$str.=" nl" if($del =~ /%nl/);
    }else{
	$str.=" raw min 255 time 1";
    }
    return $str;
}

sub getlantropars($){
    my($this)=@_;
    my $protocol=$this->getdb("protocol");
    return unless($protocol);
    my ($speed,$chr,$par,$stop,$flow)=split(/:/,$protocol);
    $flow="none" unless($flow);
    my %parity=("N"=>"none","E"=>"even","O"=>"odd");
    my @str="speed $speed";
    push @str,"character $chr";
    push @str,"parity $parity{$par}";
    push @str,"stop $stop";
    push @str,"flow $flow";
    return @str;
}

############## EXCHANGE PROCESS ##############
sub res($){
    my($this)=@_;
    my $protocol=$this->getdb("protocol");
    my ($speed,$chr,$par,$stop,$flow,$res)=split(/:/,$protocol);
    return $res;
}

sub getwait($){
    my($this)=@_;
    my $protocol=$this->getdb("protocol");
    my ($speed,$chr,$par,$stop,$flow,$res,$wait)=split(/:/,$protocol);
    return $wait||0;
}
    

############## CONVERT STRINGS ################
sub getcompstr($$){
    my ($this,$str)=@_;
    return $str unless($this->{key});
    $this->{rver}->statprt("CMD_BEFORE=[$str]");
    # Convert Hex to Char
    $str=~s/\\([\w]{2})/(pack("C",hex($1)))/eg;
    $str=~s/\\r/\r/;
    $str=~s/\\n/\n/;
    # Add Prefix,Affix
    my $affix=$this->getdb("affix");
    if($affix){
	my %bin=("%stx"=>"\x2","%etx"=>"\x3","%enq"=>"\x5",
	    "%ack"=>"\x6","%nak"=>"\x15","%cr"=>"\r","%nl"=>"\n");
	foreach (keys %bin){
	    $affix=~ s/$_/$bin{$_}/g;
	}
	my ($pre,$del,$chk,$exp,$pos)=split(/:/,$affix);
	if($chk){
	    my $chknum="";
	    if($chk =~ /bcc/){
		$chknum ^= $_ foreach(unpack("C*",$str));
	    }elsif($chk =~ /sum/){
		$chknum=unpack("%8C*",$str);
	    }elsif($chk =~ /len/){
		$chknum=length($str);
	    }
	    my $chr=sprintf($exp,$chknum);
	    if($pos =~ /P/){
		$str=$chr.$str;
	    }else{
		$exp=~ /[1-9]/;
		$str.=substr($chr,-$&);
	    }
	}
	$str=$pre.$str.$del;
    }
    $this->{rver}->statprt("CMD_AFTER=[$str]");
    return $str;
}

sub convert($$){
    my($this,$data)=@_;
    $this->{rver}->statprt("STAT_BEFORE=[$data]");
    my ($offset,$length,$pack,$rev,$pre,$suf)=split(/:/,$this->getdb("conv"));
    if($data eq ""){
	$this->{rver}->statprt("STAT_NODATA");
	return;
    }
    if($offset =~ /\d/){
	if($length =~ /\d/){
	    $data=substr($data,$offset,$length);
	}else{
	    $data=substr($data,$offset);
	}
	$this->{rver}->statprt("STAT_SUBSTR=[$data]");
    }
    if($rev){
	$data=reverse($data); 
	$this->{rver}->statprt("STAT_REVERSE=[$data]");
    }
    if($pack){
	$data=unpack($pack,$data);
	$this->{rver}->statprt("STAT_UNPACK=[$data]");
    }else{
	$data=~ tr/ /_/ &&
	$this->{rver}->statprt("STAT_SPACE->'_'=[$data]");
	$data=~ tr/\0-\x1f/\\/d &&
	$this->{rver}->statprt("STAT_ESC->'\\' =[$data]");
    }
    $this->{rver}->statprt("STAT_AFTER=[$data]");
    return $pre.$data.$suf;
}
1;
