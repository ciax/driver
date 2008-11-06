#!/usr/bin/perl
# Last update 2001/10/4
BEGIN{
  $ENV{DRVDIR}="/home/ciax/drivers";
  $ENV{DRVVAR}="/export/scr/var-ciax";
  push @INC,"$ENV{DRVDIR}/cgi"; 
  push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
my $cgi=new CFG_cgi;
my @pars=$cgi->sortpar;
my $mode=shift @pars;
$mode=shift @ARGV unless($mode);
#print "par=$_\n" foreach(@pars);
use CFG_set_nt;
$nt=new CFG_set_nt($mode);
$nt->setstat(join("",@pars));
1;
