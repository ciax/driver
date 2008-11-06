#!/usr/bin/perl
# Last update 2003/5/24
BEGIN{
  $ENV{DRVDIR}="/home/ciax/drivers";
  $ENV{DRVVAR}="/export/scr/var-ciax";
  push @INC,"$ENV{DRVDIR}/cgi"; 
  push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
use DB_shared;

my $cgi=new CFG_cgi;
my %par=$cgi->getpar;
my $rdb=new DB_shared("db_frame.txt");
my %db=$rdb->gethash($par{mode});

print <<END;
Content-type: text/html


<HTML>
    <HEAD>
    <TITLE>MONITOR</TITLE>
    </HEAD>
    <CENTER>
    <META HTTP-EQUIV="Pragma" content="no-cache">
    <FRAMESET ROWS="$db{pix},*" FRAMEBORDER=0>
    <FRAME SRC="$db{frame1}" NAME="FRM1">
    <FRAME SRC="$db{frame2}" NAME="FRM2">
    </FRAMESET>
    </CENTER>
</HTML>
END
1;
