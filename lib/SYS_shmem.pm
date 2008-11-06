#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/10/30 Substr bugfix: substr(?,?,len)=data -> length(data) should be match to len
# 2006/10/23 SKIP if no response need (|0)
# 2006/9/28 Condition change : SHMKEY="" -> SHMKEY="" and 0
# 2005/11/30 Add a time key
# 2005/10/25 Handling warning
# 2005/10/7 Avoid error of substr
# 2005/4/30:Bugfix (cpar can be 0)
# 2005/4/28
package SYS_shmem;
use strict;
use MTN_ver;

#####
# $this->{shmkey} > 0 : Shared Memory mode
#    Begin = Read File to SHM
#    Read = SHM
#    Write = SHM
#    End = Write SHM to File;
#
# $this->{shmkey} == 0 : File mode (If can't use SHM)
#    Begin = Nothing
#    Read =  File
#    Write = File
#    End = Nothing

sub new($%){
    my($pkg,%mpar)=@_;
    my $this={};
    %{$this->{mpar}}=%mpar;
    $this->{lastpt}=0;
    my $cap=($this->{mpar}{server})?"SHMS%D":"SHMC%3";
    $this->{rver}=new MTN_ver($cap,"shm");
    $this->{ipc}=new SYS_file("$this->{mpar}{mode}.ipc","r");
    $this->{fsp}=new SYS_file("ctl_$this->{mpar}{mode}.st","s");
    bless $this;
    $this->initshm;
    return $this;
}

sub initshm($){
    my($this)=@_;
    my $buflen=512;
    $this->{len}{buffer}=$buflen;
    $this->{pointer}={all=>0,len=>$buflen};
    ($this->{shmkey})=$this->{ipc}->red;
# SHMKEY = "" or 0
    if($this->{shmkey}){
	$this->{rver}->statprt("SHMKEY=$this->{shmkey}");
	return;
    }
    return unless($this->{mpar}{server});
    my $key=shmget("ciax",$buflen,01666);
    if($key){
	$this->{shmkey}=$key;
	$this->{rver}->warning("[$this->{mpar}{mode}] SVINIT_SHMKEY=$key");
	$this->{rver}->statprt("New SHM Created");
	$this->{ipc}->wri($key);
	my($stat)=$this->{fsp}->red;
	$this->{rver}->statprt("Read Initial Data From File");
	$this->putshm("all",$stat);
    }else{
	$this->{rver}->warning("SHM=FILE MODE");
    }
}

sub endshm($){
    my($this)=@_;
    $this->{rver}->statprt("Closing SHM");
    return unless($this->{shmkey});
    $this->{fsp}->wri($this->getshm("all"));
    $this->{rver}->statprt("Write Data To File");
    shmctl($this->{shmkey},0,0);
    $this->{rver}->warning("[$this->{mpar}{mode}] SHM $this->{shmkey} Removed");
    $this->{ipc}->wri;
    $this->{shmkey}=0;
}

############## For Devices ###########
sub initdev($$){
    my($this,$updstr)=@_;
    my @chs=split(/ /,$this->{mpar}{cpar});
    my $ch=scalar @chs || 1;
    $this->newshm("time",14);
    $this->union_begin("body");
    $this->union_begin("header");
    $this->newshm("mode",4);
    $this->newshm("cme",1);
    $this->newshm("exe",1);
    $this->newshm("isu",1);
    $this->newshm("dve",1);
    $this->union_end("header");
    $this->union_begin("data");
    if($updstr =~ /[\&\|]/){
	for(my $i=1;$i<=$ch;$i++){
	    foreach(split(/\&/,$updstr)){
		my ($vkey,$buflen)=split(/\|/);
		next unless($buflen);
		$vkey="$i:$vkey" if($ch>1);
		$this->newshm($vkey,$buflen);
	    }
	}
    }else{
	$this->newshm("default");
    }
    $this->union_end("data");
    $this->union_end("body");
}

########## Define Valiables ###########
sub newshm($$$){
    my($this,$vkey,$buflen)=@_;
    return if(exists $this->{pointer}{$vkey});
    return $this->{rver}->warning("[$this->{mpar}{mode}] SHM buffer flow on [$vkey]!")	if($this->{lastpt}+$buflen > $this->{len}{buffer});
    $buflen=$this->{len}{buffer}-$this->{lastpt} unless($buflen);
    $this->{pointer}{$vkey}=$this->{lastpt};
    $this->{len}{$vkey}=$buflen;
    $this->{lastpt}+=$buflen;
    $this->{len}{all}=$this->{lastpt};
    $this->{rver}->statprt("NEWKEY($vkey:$buflen) is created");
    return 1;
}

sub union_begin($$){
    my($this,$vkey)=@_;
    return if(exists $this->{pointer}{$vkey});
    $this->{pointer}{$vkey}=$this->{lastpt};
    $this->{rver}->statprt("UNIONKEY($vkey) begin");
}

sub union_end($$){
    my($this,$vkey)=@_;
    return unless(exists $this->{pointer}{$vkey});
    $this->{len}{$vkey}=$this->{lastpt}-$this->{pointer}{$vkey};
    $this->{rver}->statprt("UNIONKEY($vkey) end");
}

########## SHM GET&PUT ########
sub getshm($$){
    my($this,$vkey)=@_;
    return $this->{rver}->warning("No such a key!($vkey)")
      unless(exists $this->{pointer}{$vkey});
    return $this->getfile($vkey) unless($this->{shmkey});
    my ($key,$res)=($this->{shmkey});
    my ($off,$len)=($this->{pointer}{$vkey},$this->{len}{$vkey});
    if(shmread($key,$res,$off,$len)){
	$res=~ tr/\0//d;
	$this->{rver}->statprt("Reading SHM($vkey):$res ($key:$off:$len)");
	return $res;
    }
    $this->{rver}->statprt("Can't read shm ($key) on redl!%1");
    shmctl($this->{shmkey},0,0);
    $this->{ipc}->wri;
    $this->{shmkey}=0;
    return $this->getfile($vkey);
}

sub putshm($$$){
    my($this,$vkey,$data)=@_;
    return unless(exists $this->{pointer}{$vkey});
    $data =~ s/ +$//g;
    $this->{len}{all}=length($data) if($vkey eq "all");
    return $this->putfile($vkey,$data) unless($this->{shmkey});
    my $key=$this->{shmkey};
    my ($off,$len)=($this->{pointer}{$vkey},$this->{len}{$vkey});
    $this->{rver}->statprt("Writing SHM($vkey):$data ($key:$off:$len)");
    return $data if(shmwrite($key,pack("A$len",$data),$off,$len));
    $this->{rver}->statprt("Can't write shm ($key) on wril!%1");
    shmctl($this->{shmkey},0,0);
    $this->putfile($vkey,$data);
    $this->{ipc}->wri;
    $this->{shmkey}=0;
    return $data;
}

sub getfile($$){
    my($this,$vkey)=@_;
    my ($stat)=$this->{fsp}->red;
    my ($off,$len,$res)=($this->{pointer}{$vkey},$this->{len}{$vkey});
    my $last=$off+$len-1;
    my $stlen=length($stat);
    $this->{rver}->statprt("[$this->{mpar}{mode}] Substr short($stat) $stlen<$last!") if($stlen < $last);
    $res=substr($stat,$off,$len);
    $res=~ tr/\0//d;
    $this->{rver}->statprt("READFILE($vkey):$res ($off:$len)");
    return $res;
}

sub putfile($$$){
    my($this,$vkey,$data)=@_;
    my ($stat)=$this->{fsp}->red;
    my ($off,$len)=($this->{pointer}{$vkey},$this->{len}{$vkey});
    my $last=$off+$len-1;
    my $stlen=length($stat);
    if($stlen < $last){
	$this->{rver}->statprt("[$this->{mpar}{mode}] Substr short($stat) $stlen<$last!");
	$stat.= '_' x ($last-$stlen);
    }
    $this->{rver}->statprt("BEFOREWRITE($vkey):$data ($off:$len) ($stat)");
    substr($stat,$off,$len)=pack("A$len",$data);
    $this->{rver}->statprt("WRITEFILE($vkey):$data ($off:$len) ($stat)");
    $this->{fsp}->wri($stat);
}
1;
