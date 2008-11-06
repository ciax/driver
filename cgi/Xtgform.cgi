#!/usr/bin/perl
BEGIN{
  $ENV{DRVDIR}="/home/ciax/drivers";
  $ENV{DRVVAR}="/export/scr/var-ciax";
  push @INC,"$ENV{DRVDIR}/cgi"; 
  push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_set_tag;
use CFG_cgi;

$cgi=new CFG_cgi;
my @pars=$cgi->sortpar;

$tgh=new CFG_set_tag;
$tgh->setstat(@pars);
1;
