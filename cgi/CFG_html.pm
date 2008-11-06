#!/usr/bin/perl -wc
# Last update 2003/1/7
package CFG_html;

sub new($){
    my($pkg)=@_;
    my $this={};
    bless $this;
}

################  Html subroutine ##############

sub cgi_header($$$){
  my($this,$title,$pull)=@_;
  my $str= "Content-type: text/html\n\n";
  $str .= "<HTML>\n<HEAD><TITLE>";
  $str .= $title;
  $str .= "</TITLE>\n";
  $str .="<META HTTP-EQUIV=REFRESH CONTENT=$pull>\n" if($pull);
  $str .="</HEAD>\n<BODY BGCOLOR=#DDDDDD TEXT=#0000FF><CENTER>\n";
  return $str;
}

sub cgi_footer($){
  my($this)=@_;
  return "</BODY>\n</HTML>\n";
}
sub push_header($){
    my($this)=@_;
    my $str= "HTTP/1.0 200 OK\n";
    $str .="Content-type: multipart/x-mixed-replace;";
    $str .="boundary=---ThisRandomString---\n\n";
    return $str;
}

sub push_bd($){
  my($this)=@_;
  return "---ThisRandomString---\n";
}

########### General Section ##############
sub headline($$$){
  my($this,$lev,$caption)=@_;
  return "<H$lev>$caption</H$lev>\n";
}

sub gohome($){
  my($this)=@_;
  my $str = "<H3><FORM>\n";
  $str .= qq[<INPUT TYPE="button" VALUE="HOME" ];
  $str .= qq[ONCLICK="location='/ciaxctl.html'">\n];
  $str .= "</FORM></H3>\n";
  return $str;
}
############  Table Section  ############
sub tbl_line($@){
  my($this,@data)=@_;
  my $rslt="<TR>\n";
  my ($colm,$bg)=(0);
  foreach my $str (@data){
    if($colm++ %2){
	$str.=($str=~/%$/)?"1":"%2";
	$str=$this->color($str);
    }
    $rslt .="<TD>$str</TD>\n"; 
  }
  return $rslt."</TR>\n";
}

sub tbl_head($){
  my($this)=@_;
  return qq[<TABLE BORDER="3" CELLSPACING="2" CELLPADDING="3" BORDERCOLORDARK=#666666 WIDTH=100%>\n];
}
sub tbl_end($){
  my($this)=@_;
  return "</TABLE>\n";
}

### Coloring subroutines ###
# 1=RED,2=GREEN,4=BLUE,9=LIGHT RED,A=LIGHT GREEN,C=LIGHT BLUE
sub color($$$){
    my($this,$data)=@_;
    my ($str,$color)=split(/%/,$data);
    return $str unless($color);
    my $num=hex($color);
    my $chr="77";
#    my $chr=($num & 8)?"44":"88";
    my $red=($num & 1)?$chr:"00";
    my $green=($num & 2)?$chr:"00";
    my $blue=($num & 4)?$chr:"00";
    my $col="#$red$green$blue";
    return "<FONT COLOR=$col>".$str."</FONT>";
}
1;
