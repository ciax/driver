#!/usr/bin/perl

print "!mode,,cmd,caption,group,cmdstr,stop,skp,alws\n";
foreach (@ARGV){
    my $mode=substr($_,4,3);
    if(/^cdb/){
	open(IDB,"idb_$mode.txt");
	@idb=<IDB>;
	chomp @idb;
	close(IDB);
    }
    open(HDL,$_);
    foreach (<HDL>){
	next if(/^[#\*]/);
	chomp;
	my ($code,$caption,$cmd,$stop)=split(/,/);
	next unless($code);
	$code=~tr/!//d;
	my ($idbline)=grep(/$code/,@idb);
	my ($c,$skip,$need)=split(/,/,$idbline);
	print join(",",$mode,$code,$caption,$cmd,$stop,$skip,$need);
	print "\n";
    }
    close(HDL);
}
