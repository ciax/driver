#!/usr/bin/perl
BEGIN{
  $ENV{DRVDIR}="/home/ciax/drivers";
  $ENV{DRVVAR}="/export/scr/var-ciax";
  push @INC,"$ENV{DRVDIR}/cgi"; 
  push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
my $cgi=new CFG_cgi;
my @pars=$cgi->sortpar;

my $cart=shift @pars;
if(scalar @pars == 1){
    my $inst.=shift @pars;
    $cart="$cart:$inst";
}
use CFG_set_jak;
my $jk=new CFG_set_jak($cart);
$jk->setstat(@pars);
1;
