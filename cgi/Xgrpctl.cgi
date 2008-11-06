#!/usr/bin/perl
# Last update 2003/7/9
BEGIN{
    $ENV{DRVDIR}="/home/ciax/drivers";
    $ENV{DRVVAR}="/export/scr/var-ciax";
    push @INC,"$ENV{DRVDIR}/cgi"; 
    push @INC,"$ENV{DRVDIR}/lib"; 
}
use CFG_cgi;
use DB_stat;

my $cgi=new CFG_cgi;
my %par=$cgi->getpar;
my $mode=$par{mode};
my $sdb=new DB_stat($mode);
my @ch=grep(/ch[0-9]/,$sdb->getkeys);
my $num=scalar @ch;
my $chkbox="";
foreach(@ch){
    $chkbox.="    ".$_.'<INPUT TYPE="checkbox" checked>'."\n";
}

print <<END;
Content-type: text/html


<HTML>
  <HEAD>
  <TITLE> Graph Control</TITLE>
  </HEAD>
  <BODY BGCOLOR=#FFFFFF topmargine=0 onLoad="getClock()" onLoad="setInterval('grpctl(0,0)',300000)">
  <CENTER>
  <SCRIPT LANGUAGE="JavaScript">
  offset=0;
  len=0;
  function grpctl(roff,rlen){
      len+=rlen;
      if(len < 0 ){
	  len = 0;
      }
      offset+=roff*Math.pow(2,len)*0.64;
      if(offset < 0){
	  offset=0;
      }
      var chk="";
      for (i=0;i<$num;i++){
	  if(document.forms[0].elements[i].checked){
	      chk+=(i+1)+",";
	  }
      }
      var par="mode=$mode&off="+offset+"&len="+len+"&ch="+chk;
      parent.FRM1.location.href="Xgraph.cgi?"+par;
  }
  function getClock(){
      now = new Date();
      yer = now.getYear();
      mon = now.getMonth()+1;
      dat = now.getDate();
      hou = now.getHours();
      min = now.getMinutes();
      sec = now.getSeconds();
      document.forms[0].clock.value=yer+"/"+mon+"/"+dat+" "+hou+":"+min+":"+sec;
      setTimeout("getClock()",1000);
  }
  </SCRIPT>
  <FORM>
  $chkbox
  <INPUT TYPE=button VALUE="<" ONCLICK=grpctl(50,0)>
  <INPUT TYPE=button VALUE="-" ONCLICK=grpctl(0,1)>
  <INPUT TYPE=button VALUE="+" ONCLICK=grpctl(0,-1)>
  <INPUT TYPE=button VALUE=">" ONCLICK=grpctl(-50,0)>
  <INPUT TYPE=button VALUE="UPD" ONCLICK=grpctl(0,0)>
  <INPUT TYPE=text name="clock" size=20>
  </FORM>
  </CENTER>
  </BODY>
  </HTML>
END
1;
