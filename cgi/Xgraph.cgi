#!/usr/bin/perl
# Last update 2003/5/24
BEGIN{
    $ENV{DRVDIR}="/home/ciax/drivers";
    $ENV{DRVVAR}="/export/scr/var-ciax";
    push @INC,"$ENV{DRVDIR}/cgi"; 
    push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
use CFG_graph;

my $cgi=new CFG_cgi;
my %par=$cgi->getpar;

my $rg=new CFG_graph($par{mode},$par{off},$par{len},$par{ch});
binmode(STDOUT);
print "Content-Type: image/png\n\n";
print $rg->printgraph;

1;
