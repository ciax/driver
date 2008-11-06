#!/usr/bin/perl
# Last update 2003/8/11
BEGIN{
    $ENV{DRVDIR}="$ENV{HOME}/drivers" unless($ENV{DRVDIR});
    $ENV{DRVVAR}="$ENV{HOME}/var" unless($ENV{DRVVAR});
    push @INC,"$ENV{DRVDIR}/lib"; 
}
use SYS_stdio;

(@ARGV) || die "Usage:logren [files]\n";
my $rprt=new SYS_stdio;
my @output=();
my @files=sort(@ARGV);
my ($s,$mi,$h,$d,$mo,$y)=localtime;
my $today=sprintf("%02d%02d%02d",$y-100,$mo+1,$d);
foreach(@files){
    next unless(-e $_);
    push @output,$_;
    next unless(/log$/);
    my $id=$_;
    my @line=grep(/^\d+/,`head $_;tail $_`);
    my ($head)=($line[0] =~ /^(\d+)/);
    my ($tail)=($line[-1] =~ /^(\d+)/);
    if(/^mcr/){
	$id=~ s/(-[0-9]|\.).*$//g;
    }else{
	my @st=grep(/%/,@line);
	($id)=($st[0] =~ /^\d{6}-\d{6} +%([\w]{3})/);
	unless($id){
	    print $rprt->color("$_ is%3")."\n";
	    system "cat $_";
	    print $rprt->color("Delete?%1");
	    my $input=<STDIN>;
	    unlink $_ if($input=~/[Yy]/);
	    pop @output;
	    next;
	}
    }
    next if($tail=~/^$today/);
    my $newfile="$id-$head";
    if($head eq $tail){
	$newfile.=".log";
    }else{
	$newfile.="-$tail.log";
    }
    next if($newfile eq $_);
    print "$_ -> ";
    if(-e $newfile){
	print "$newfile aleady exists\n";
	if(`diff $_ $newfile`){
	    system("sort -u $_ $newfile > temp.log");
	    rename "temp.log",$newfile;
	    print $rprt->color("Different file -> $_ and $newfile is merged!%2")."\n";
	}else{
	    print $rprt->color("Same file -> $_ is deleted!%4")."\n";
	}
	unlink $_;
	pop @output;
	next;
    }
    rename $_,$newfile;
    print "$newfile\n";
}
exit 0 if(scalar @output > 0);
warn "NOFILES\n";
exit 100;
1;
