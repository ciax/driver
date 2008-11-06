#!/usr/bin/perl
# Last update 2003/7/14
BEGIN{
  $ENV{DRVDIR}="/home/ciax/drivers";
  $ENV{DRVVAR}="/export/scr/var-ciax";
  push @INC,"$ENV{DRVDIR}/cgi"; 
  push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
use DB_mode;
use CLI_cmd;

my $cgi=new CFG_cgi;

my %par=$cgi->getpar;
my ($mode,$cmd)=split(":",$par{on});
if($par{sw}=~/on/){
    my $hour=`date +%H`;
    if($hour < 8 or $hour > 17){
	$exestr=" -- <FONT COLOR=#FF0000>CAN'T ON</FONT>\n";
	$mode="";
    }else{
	$exestr=" -- <FONT COLOR=#FF0000>SW(ON)</FONT>\n";
    }
}elsif($par{sw}=~/off/){
    $cmd="stop";
    $exestr=" -- <FONT COLOR=#FF0000>SW(OFF)</FONT>\n";
}else{
    $mode="";
}
if($mode){
    my $rmod=new DB_mode($mode," ");
    my $rcom=new CLI_cmd($rmod->getmpar);
    my $stat=$rcom->setcmd($cmd);
}

print <<END;
Content-type: text/html


<HTML><HEAD>
<TITLE>COMMAND</TITLE>
</HEAD>
<BODY BGCOLOR=#FFFFFF><CENTER>
<SCRIPT LANGUAGE="JavaScript">
    function ccdctl(on,sw){
	location.replace("Xccdctl.cgi?on="+on+"&sw="+sw);
    }
</SCRIPT>
<FORM>
Light
<INPUT TYPE=button VALUE="ON" ONCLICK=ccdctl("$par{on}","on")>
<INPUT TYPE=button VALUE="OFF" ONCLICK=ccdctl("$par{on}","off")>
$exestr
</FORM>
</BODY>
</HTML>
END
1;


