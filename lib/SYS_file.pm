#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Dependency level 1
# Last update:2006/6/20 ADD /$var/par dir
# 2005/9/30 Chown ciax at creating file if uid=root
# 2005/9/28 Error handling for glob expression
# 2005/5/16: Add $this->{dir} valiable
# 2004/12/27
package SYS_file;
use strict;
use MTN_ver;

sub new($$$){
    my($pkg,$filename,$id)=@_;
    die "No filename $filename" unless($filename =~ /[a-z]/);
    my $this ={};
    my $path="";
    umask(0);
    if($id eq "c"){
        $path="$ENV{DRVDIR}/config/";
	$this->{ronly}=1; # Read only
    }elsif($id eq "d"){
	$path="$ENV{DRVDIR}/dmydata/";
	$this->{ronly}=1; # Read only
    }elsif($id eq "p"){
	$path="$ENV{DRVVAR}/par/";
    }elsif($id eq "s"){
	$path="$ENV{DRVVAR}/status/";
    }elsif($id eq "n"){
	$path="$ENV{DRVVAR}/ntshare/";
    }elsif($id eq "l"){
	$path="$ENV{DRVVAR}/log/";
	$this->{aonly}=1; # Append only
	$filename.=".log";
    }elsif($id eq "L"){
	$path="$ENV{DRVVAR}/log/";
	$this->{ronly}=1;
    }elsif($id eq "r"){
	$path="$ENV{DRVVAR}/run/";
    }else{
	die("No such option($id)");
    }
    bless $this;
    die("You can't use file glob!\n") if($filename=~ /\*/ and $this->{ronly} !=1);
    $this->{rver}=new MTN_ver("$filename%5","file");
    $filename=$path.$filename;
    $filename=~ s/.*\///;
    $this->{path}=$this->makepath($&).$filename;
    $this->{file}=$filename;
    $this->{rver}->statprt("Filepath=$this->{path}($id)");
    return $this;
}

sub chx($$){
    my ($this,$path)=@_;
    my ($l,$p,$uid,$gid)=getpwnam("ciax") or die("No user ciax!\n");
    chown($uid,$gid,$path) unless($>);
}
    
sub makepath($$){
    my ($this,$dir)=@_;
    return $dir unless($dir =~ /\//);
    my @dirname=split("/",$dir);
    my $path="";
    foreach(@dirname){
	next unless($_);
	$path.="/$_";
	unless(-e $path){
	    mkdir($path,0777);
	    $this->chx($path);
	    $this->{rver}->warning("Directry $path created!");
	}
    }
    $this->{dir}=$path."/";
    return $this->{dir};
}

sub exists($){
    my ($this)=@_;
    return 1 if(-e $this->{path});
}

sub fname($){
    my ($this)=@_;
    return $this->{file};
}

sub clr($){
    my ($this)=@_;
    $this->wri;
}

# Write data to file (the return value must be array)
sub wri($@){
    my ($this,@data)=@_;
    my $path=$this->{path};
    die ("Glob expression for writing file ($path)\n") if($path=~ /\*\?\]\[/);
    $this->{rver}->statprt("Write [$data[0]] to $this->{file}");
    die ("Configure file [$this->{file}] is read only!") if($this->{ronly});
    die ("Log file [$this->{file}] is append only!") if($this->{aonly});
    $this->{rver}->warning("$path does't exist then create it!") unless(-e $path);
    open(HDL,">$path") or die ("Can't write open $path\n");
    flock(HDL,2);
    print(HDL "$_\n") foreach(@data);
    close(HDL);
    $this->chx($path);
    return @data;
}

# Read data from file
sub red($){
    my ($this)=@_;
    my @lines=();
    my @path=glob($this->{path});
    die ("No such files ($this->{path})\n") unless(scalar @path);
    $this->wri("0") if(! -e $this->{path} and $this->{ronly} != 1);
    foreach(@path){
	open(HDL,"$_") or die ("Can't read open $_\n");
	flock(HDL,1);
	my @data=grep(!/^[ \t]*#/,<HDL>);
	close(HDL);
	map(s/ *$//,@data);
	chomp @data;
	$this->{rver}->statprt("Read [$data[0]] from $_");
	push @lines,@data;
    }
    return @lines;
}

# Read data from last
sub tail($$){
    my ($this,$lines)=@_;
    my $path=$this->{path};
    $this->wri("0") unless(-e $path);
    ############
    my @res=`tail -n $lines $path`;
    chomp @res;
    $this->{rver}->statprt("Read [$res[0]] from $this->{file}");
    return @res;
#    ################
#    my $buffer=80;
#    my ($counter,$offset,$head,@data,@res)=(0,-$buffer);
#    open(HDL,"$path") or die ("Can't read open $path\n");
#    select(HDL);$|=1;select(STDOUT);flock(HDL,1);
#    while($counter < $lines){
#	my $str=undef;
#	last unless(seek(HDL,$offset,2));
#	last unless(read(HDL,$str,$buffer));
#	$offset-=$buffer;
#	$str.=$head;
#	my @strs=split("\n",$str);
#	$head=shift @strs;
#	$counter+=scalar @strs;
#	unshift @data,@strs;
#    }
#    close(HDL);
#    for(my $i=$counter-$lines;$i<$counter;$i++){
#	my $str=$data[$i];
#	$str=~s/ *$//;
#	chomp $str;
#	next unless($str);
#	push @res,$str;
#   }
#    $this->{rver}->statprt("Tail [$res[0]] from $this->{file}");
#    return @res;
}

# Append data to file (the return value must be array)
sub append($@){
    my ($this,@data)=@_;
    my $path=$this->{path};
    $this->{rver}->statprt("Append [$data[0]] to $this->{file}");
    die ("Configure file [$this->{file}] is read only!") if($this->{ronly});
    $this->{rver}->warning("New file is created $path!") unless(-e $path);
    open(HDL,">>$path") or die ("Can't write open $path\n");
    flock(HDL,2);
    print(HDL map("$_\n",@data));
    close(HDL);
}

sub rmline($$){
    my($this,$exp)=@_;
    my @data=$this->red;
    $this->wri(grep(!/$exp/,@data));
}
    
# Check file Flag for NT station
sub chkflg($){
    my($this)=@_;
    my ($data)=$this->red;
    return substr($data,0,1);
}

sub getval($@){
    my ($this,@val)=@_;
    my %res=();
    foreach (@val){
	next unless($_);
	my($name,$val)=split(/=/,$_);
	$res{$name}=$val;
    }
    return %res;
}

sub putval($%){
    my ($this,%a)=@_;
    my @res=();
    foreach (keys %a){
	next unless($_);
	push @res,"$_=$a{$_}";
    }
    return @res;
}
1;

