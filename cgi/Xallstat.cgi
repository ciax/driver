#!/usr/bin/perl
BEGIN{
    $ENV{DRVDIR}="/home/ciax/drivers";
    $ENV{DRVVAR}="/export/scr/var-ciax";
    push @INC,"$ENV{DRVDIR}/cgi"; 
    push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_html;
use CFG_get_all;
use CFG_cgi;

my $cgi=new CFG_cgi;
my %pars=$cgi->getpar;
my $mode=$pars{mode};

#$mode=$ARGV[0] if(!$mode);

$html=new CFG_html;
my $rdev=new CFG_get_all($mode);
print $html->cgi_header(uc($mode)." STATUS",2);
print $rdev->viewstat;
print $html->cgi_footer;
1;
