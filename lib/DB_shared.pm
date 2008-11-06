#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2006/7/10: print -> warn for exit
# 2004/2/10
package DB_shared;
use strict;
use SYS_file;
use SYS_stdio;

# You should set the index before reading data
sub new($$$){
    my($pkg,$file,$usage)=@_;
    my $this={usage=>$usage};
    my $rf=new SYS_file($file,"c");
    my @lines=grep(!/^$/,$rf->red); 
    @{$this->{index}}=("!key");
    $this->{file}=$rf->{file};
    bless $this;
    $this->insdb(@lines);
    return $this;
}

# INSERT INTO <TABLE> VALUES(@lines)
sub insdb($@){
    my($this,@lines)=@_;
    my @index=@{$this->{index}};
    foreach(@lines){
	my @fields=split(",");
	my $key=$fields[0];
	if($key =~ /^!key/){
	    @index=@fields;
	    shift @fields;
	    push @{$this->{index}},@fields;
	    next;
	}
	die("Index is not set before data setting!\n")
	  if(scalar @{$this->{index}} < 2);
	foreach (@index){
	    $this->{hash}{$key}{$_}=shift @fields;
        } 
	push @{$this->{id}},$key;
    }
}

sub getkeys($){
    my($this)=@_;
    return @{$this->{id}};
}

sub setkey($$){
    my($this,$key)=@_;
    while($key=~/\// and not exists $this->{hash}{$key}){
	$key=~ s/\/.*?$//;
    }
    if($key and exists $this->{hash}{$key}){
	$this->{key}=$key;
	return $key
    }elsif($this->{usage}){
	$0=~ s/.*\///;
	my $name=($this->{usage}=~/$0/)?"":$0." ";
	warn "USAGE : $name$this->{usage}\n";
	warn "No such a key [$key]!\n" if($key);
	$this->helpout;
	exit 10;
    }elsif(!$key){
	$this->helpout;
    }
    return;
}

sub setlkey($$){
    my($this,$key)=@_;
    my $lkey="";
    foreach (keys(%{$this->{hash}})){
	$lkey=$_ if($key=~/^$_/ and /$lkey/);
    }
    $this->{key}=$lkey if($lkey);
    return $lkey;
}

# SELECT $field FROM <TABLE> WHERE <ID> = $key
# Field is substituted with "<FILENAME>"
# Delimiter is substituted with "&"
# Escape character is Explained by "\XX"
sub getdb($$$){
    my($this,$field,$key)=@_;
    warn("No key on FIELD=$field") if($key.$this->{key} eq undef);
    my %hash=$this->gethash($key);
    if(exists $hash{$field}){
	my $str=$hash{$field};
	$str=~s/\<(.+)\>/`cat $ENV{DRVVAR}\/status\/$1`/eg;
	$str=~ tr/\n/&/;
#	$str=join("&",split(/\n/,$str));
	$str=~s/\\([0-9A-Fa-f]+)/chr(hex($1))/eg;
	return $str;
    }
    die("No such a field name [$field] on $this->{file}!")
	unless(grep(/$field/,@{$this->{index}}));
    return;
}

# SELECT * FROM <TABLE> WHERE <ID> = $key
sub gethash($$){
    my($this,$key)=@_;
    $key=$this->{key} if($key eq "");
    warn("KEY is undefined!")if($key eq undef);
    return %{$this->{hash}{$key}} if(exists $this->{hash}{$key});
}

# SELECT <ID> FROM <TABLE> WHERE $field = $str 
sub search($$$){
    my($this,$field,$str)=@_;
    my @db=();
    foreach(@{$this->{id}}){
	my %hash=$this->gethash($_);
	if($hash{$field}=~ /$str/){
	    push @db,$hash{'!key'};
	}
    }
    return @db;
}

# SELECT <ID> FROM <TABLE> WHERE $field = $str
# $outcol format "field1,field2,..."
sub sqlsel($$$$){
    my($this,$outcol,$field,$str)=@_;
    my $not=($str=~ /^!/);
    $str=~ tr/!//d;
    my @cols=split(",",$outcol);
    my @db=();
    foreach(@{$this->{id}}){
	my %hash=$this->gethash($_);
	my $match=0;
	if($not){
	    $match=1 if($hash{$field} ne $str);
	}else{
	    $match=1 if($hash{$field} eq $str);
	}
	if($match){
	    my @data=();
	    push @data,$hash{$_} foreach (@cols);
	    push @db,join(",",@data);
	}
    }
    return @db;
}

sub helpout($$){
    my($this,$exit)=@_;
    my $rpr=new SYS_stdio;
    my @help=$this->sqlsel("!key,caption","inv","");
    $rpr->helpout(@help);
}
1;
