#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 
# 2006/12/12: SQL (Float) input '****' -> 0
# 2006/10/30 add setdate, add getbody
# 2006/10/25: Special tag's prefix is "%"
# 2006/10/25: Add pre substr function
# 2006/6/22: Non reading status -> "****" at num
# 2006/4/6: Name change: sub csv() -> sub sym()
# 2006/1/30: csv,raw gives array
# 2005/5/15: Debug (Duplicated color code on num string)
# 2004/12/9
package DB_stat;
use strict;
use DB_shared;
use SYS_stdio;

sub new($$$$){
    my($pkg,$mode,$caption,$noheader)=@_;
    my $this={title=>$caption,mode=>$mode};
    my $rsdb=new SYS_file("sdb_$mode.txt","c");
    my @sdb=$rsdb->red;
    bless $this;
    unshift @sdb,('cme,COMERR,1,ENUM,_=-! E=E%','exe,EXEC,1,ENUM,0=- 1=X%3',,
	       'isu,ISSUE,1,ENUM,0=- 1=I%3','dve,DRVERR,1,ENUM,_=-! E=E%','')
	unless($noheader);
    $this->init(@sdb);
    return $this;
}

## fnt option is for Forced NT status set CGI
# Pre substr WHERE id = %sub, caption: before/after by regexp
# packstr1: SELECT caption,len FROM table WHERE id = "%pck"
# packstr2: SELECT len FROM table WHERE id != "%pck"
sub init($@){
    my($this,@sdb)=@_;
    @{$this->{line}}=grep(!/^%/,@sdb);
    my ($count)=();
    foreach(@sdb){
	next unless($_);
	my ($key,$caption,$len,$ftype,$opt)=split(/,/);
	if($key =~ /%pck/){
	    my $pack=($caption ne "")?$caption:"b";
	    push @{$this->{bin2}},"$pack$len";
	    $count+=$len;
	}elsif($key =~ /%sub/){
	    push @{$this->{sub}},$caption;
	}else{
	    push @{$this->{keys}},$key;
	    $this->{sym}{$key}{caption}=$caption;
	    $this->{sym}{$key}{option}=$opt;
	    $this->{sym}{$key}{ftype}=$ftype;
	    if($count > 0){
		$count-=$len;
	    }else{
		push @{$this->{bin2}},"A$len";
	    }	
	    $this->{pck2} .= "A$len";
	}
    }
    $this->{bin1}=join(' ',@{$this->{bin2}});
    $this->{pck1}=$this->{bin1};# if($this->{bin1} =~ /b/);
    $this->{bin1} =~ s/[Bb][0-9]/A1/g;
}

########  Data Inport Service #########
sub setdate($$){
    my($this,$date)=@_;
    $date =~ s/ +$//;
    $this->{date}=$date;
}

sub setdef($$){
    my($this,$stat)=@_;
    return unless($stat =~ /^%/);
    $this->{body}=$stat;
    $stat =~ tr/ /_/;
    foreach(@{$this->{sub}}){
	my ($b,$a)=split('/');
	$stat=~ s/$b/$a/g;
    }
    my $local=substr($stat,4);
    my @keys=@{$this->{keys}};
    if($this->{pck1} ne ""){
	my @strs=unpack($this->{bin1},$local);
	$local="";
	foreach (@{$this->{bin2}}){
	    my $str=shift @strs;
	    $str =~ tr/a-fA-F/j-oJ-O/ if(/b/);
	    $local.=$str;
	}
	$local=join("",unpack($this->{pck1},$local));
    }	
    foreach(unpack($this->{pck2},$local)){
	my $key=shift @keys;
	$this->{sym}{$key}{value}=$_;
    }
}


######## Data Abstraction Services ########
sub getraw($$){
    my($this,$key)=@_;
    return $this->{sym}{$key}{value};
}

sub getsym($$){
    my($this,$key)=@_;
    my $opt=$this->{sym}{$key}{option};
    my $val=$this->{sym}{$key}{value};
    if($opt =~ /^%ist/){
	return $this->inst($val);
    }elsif($opt =~ /^%/){ # Can be [+-0123456789]
	return $this->number($val,$opt);
    }else{
	my $def="";
	foreach(split(/ /,$opt)){
	    my($str,$sym)=split(/=/);
	    return $sym if($val =~ /$str/);
	    $def=$sym if($str eq "DEF");
	}
	return $def if($def ne "");
    }
    return $val;
}

sub getcaption($$){
    my($this,$key)=@_;
    return $this->{sym}{$key}{caption};
}

sub getbody($){
    my($this)=@_;
    return $this->{body};
}

sub getkeys($){
    my($this)=@_;
    return @{$this->{keys}};
}

sub number($$$){
    my($this,$val,$opt)=@_;
    return $val if($val=~/^\*+$/);
    $val =~ tr/_//d;
    # Index: Format on printf, Remarkable value splited by /, Tolerance, Coefficient, Offset
    my ($fmt,$spcfy,$tl,$coe,$ofs)=split(/ /,$opt);
    $coe=$coe || 1;
    my $ext="";
    # Sign&Decimal Converter (For CIAX3 & K3NR)
    if($fmt =~ tr/://d){
	if($fmt =~ /\+/){
	    my ($sign,$real)=unpack("AA*",$val);
	    $val=($sign)?(-$real):$real;
	}
	if($fmt =~ /\./){
	    my($re,$dec)=split(/\./,$fmt);
	    $dec =~ tr/[0-9]//c;
	    $val=$val/(10**$dec);
	}
    }
    # Hex Converter
    if($fmt =~ /!/){
	$fmt =~ tr/!//d;
	$val=hex($val);
    }
    foreach(split('/',$spcfy)){
        my ($nm,$sm)=split(":");
	if(abs($val-$nm) < $tl){
	    $ext="/$sm";
	    $ext.="%3" if($ext!~/%/);
	}
    }
    my $sym=sprintf($fmt,($val+$ofs)*$coe);
    return $sym.$ext;
}

sub inst($$){
    my($this,$val)=@_;
    return unless($val =~ /\d/);
    $this->{rit}=new DB_shared("db_inst.txt") if(not exists $this->{rit});
    return $this->{rit}->getdb("inst",$val);
}

######## Data Print Services ########
#### JSON Output ####
sub json($){
    my ($this)=@_;
    my @stat=$this->sym;
    map(s/(.+)=(.+)/"$1":"$2"/,@stat);
    return "{".join(",",@stat)."}";
}

#### Console Output ####
sub sym($){
    my ($this)=@_;
    my @stat=($this->{date})?("time=$this->{date}"):();
    push @stat,"mode=$this->{mode}";
    foreach(@{$this->{keys}}){
	next unless($_);
	my $sym=$this->getsym($_);
	$sym =~ s/!$//g;
	$sym =~ s/%\d*$//g;
	push @stat,"$_=$sym";
    }
    return @stat;
}

sub raw($){
    my ($this)=@_;
    my @stat=($this->{date})?("time=$this->{date}"):();
    push @stat,"mode=$this->{mode}";
    foreach(@{$this->{keys}}){
	next unless($_);
	my $raw=$this->getraw($_);
	push @stat,"$_=$raw";
    }
    return @stat;
}

sub prt($$){
    my ($this,$ver)=@_;
    my $rprt=new SYS_stdio;
    my (@lines,$line)=();
    my @keys=@{$this->{keys}};
    foreach(@{$this->{line}}){
	if($_ ne ""){
	    my $key=shift @keys;
	    my $caption=$this->getcaption($key);
	    my $sym=$this->getsym($key);
	    $sym =~ tr/_//d;
	    $sym.="1" if($sym =~ /%$/);
	    $sym.="%2" if($sym !~ /%/);
	    my ($s,$c)=split(/%/,$sym);
	    my $len=15-length($s.$caption);
	    $sym=$rprt->color($sym);
	    $caption=$rprt->color("$caption%6");
	    $line.="  [$caption:$sym]"." "x $len 
		if($key ne "" and ($sym !~ /!/ or $ver ne ""));
	}else{
	    push @lines,$line if($line ne "");
	    $line="";
	}
    }
    push @lines,$line if($line ne "");
    my $title=$rprt->color("  ******** $this->{title} ********%3");
    return ($title,@lines);
}
#### HTML Output ####
sub form($){
    my ($this)=@_;
    my (@fld,@rec)=();
    my @keys=@{$this->{keys}};
    foreach(@{$this->{line}}){
	if($_ ne ""){
	    my $key=shift @keys;
	    my $caption=$this->getcaption($key);
	    my $raw=$this->getraw($key);
	    push @fld,"$caption;$raw;$this->{sym}{$key}{option}";
	}else{
	    push @rec,join(",",@fld) if(scalar @fld);
	    @fld=();
	}
    }
    return @rec,join(",",@fld);
}

sub table($){
    my ($this)=@_;
    my (@fld,@rec)=();
    my @keys=@{$this->{keys}};
    foreach(@{$this->{line}}){
	if($_){
	    my $key=shift @keys;
	    my $caption=$this->getcaption($key);
	    my $sym=$this->getsym($key);
	    if($key and $sym!~/!/){
		push @fld,"$caption;$sym";
	    }
	}else{
	    push @rec,join(",",@fld) if(scalar @fld);
	    @fld=();
	}
    }
    return @rec,join(",",@fld);
}

#### SQL Output ####
sub sqlinsert($$){
    my ($this,$time)=@_;
    my @sym=();
    foreach(@{$this->{keys}}){
	next unless($_);
	next if(/(cme|exe|isu|dve)/);
	my $symbol=$this->getsym($_);
	if($this->{sym}{$_}{ftype} eq "FLOAT"){
	    $symbol =~ s/\*+/0/;
	    $symbol =~ s/\/.*$//;
	}else{
	    $symbol="'$symbol'";
	}
	push @sym,"$_=$symbol";
    }
    $time=$time || "NOW()";
    unshift @sym,"time=$time";
    my $str="INSERT INTO log_$this->{mode} SET ";
    $str.=join(',',@sym).";";
    return $str;
}

sub sqlcreate($){
    my($this)=@_;
    my $key="time";
    my $define="($key TIMESTAMP(12),";
    $define.=join(",",$this->sqldefine);
    $define.=",PRIMARY KEY ($key) );";
    return "CREATE TABLE log_$this->{mode} $define"; 
}

sub sqlalter($$){
    my($this,$num)=@_;
    my @add=$this->sqldefine;
    my $repl="";
    foreach (@add[$num..$#add]){
	$repl.="ALTER TABLE log_$this->{mode} ADD $_;\n"; 
    }
    return $repl;
}

sub sqldefine($){
    my($this)=@_;
    my @define=();
    foreach (@{$this->{line}}){
	next if(/^(,| *$|cme|exe|isu|dve)/);
	my ($id,$cap,$len,$type,$opt)=split(/,/);
	my $elm="$id $type";
	if($type eq "ENUM"){
	    my @opts;
	    foreach(split(/ /,$opt)){
		s/^.*=//;
		push @opts,$_;
	    }
	    $elm.=" ('".join("','",@opts)."')";
	}elsif($type eq "CHAR"){
	    $elm.="($len)";
	}else{
	    $elm.=" default 0";
	}
	push @define,$elm;
    }
    return @define
}
1;
