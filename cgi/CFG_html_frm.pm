#!/usr/bin/perl -wc
# Last update 2003/3/6
package CFG_html_frm;
use CFG_html;
@ISA=qw(CFG_html);

sub new($$$){
    my($pkg,$mid,$path)=@_;
    my $this=new CFG_html;
    $this->{id}="A000";
    $this->{mid}=$mid;
    my @dir=split(/\//,$path);
    $this->{cgif}=pop @dir;
    bless $this;
}

######### Internal subroutine for select ##########
sub _selhead($){
    my($this)=@_;
    my $id=$this->{id}++;
    return qq[<SELECT NAME="$id">\n];
}
sub _selend($){
    my($this)=@_;
    return "</SELECT>";
}
sub _option($$$){
    my($this,$val,$opt)=@_;
    my ($sel,$sbl)=split(/=/,$opt);
    $sbl=~ s/%.*//g;
    $sel=substr($sel."_"x100,0,length($val));
    my $str = qq[<OPTION VALUE="$sel"];
    $str .= " SELECTED" if($sel eq $val);
    $sbl =~ tr/_$//d;
    $str .= qq[>$sbl</OPTION>\n];
    return $str;
}

###########  Form Section ################
sub frm_head($){
    my($this)=@_;
    my $str=qq[<FORM ACTION="$this->{cgif}" METHOD="POST">\n];
    return $str.$this->frm_hidden($this->{mid});
}
sub frm_text($$){
    my($this,$val)=@_;
    my $id=$this->{id}++;
    return qq[<INPUT TYPE="text" SIZE="6" NAME="$id" VALUE="$val">\n];
}

sub frm_select($$$){
    my($this,$val,$opt)=@_;
    my $str=$this->_selhead;
    my @opts=split(/ /,$opt);
    unshift @opts,"$val=$val" unless($opt);
    $str .= $this->_option($val,$_) foreach (@opts);
    $str .= $this->_selend;
    return $str;
}

sub frm_selbin($$){
    my($this,$val)=@_;
    my $str=$this->_selhead;
    $str .= $this->_option($val,"1=1");
    $str .= $this->_option($val,"0=0");
    $str .= $this->_selend;
    return $str;
}

sub frm_submit($){
    my($this)=@_;
    return qq[<H3><INPUT TYPE="Submit" VALUE="OK"></H3>\n</FORM>\n];
}

sub frm_hidden($$){
    my($this,$str)=@_;
    my $id=$this->{id}++;
    return qq[<INPUT TYPE="Hidden" NAME="$id" VALUE="$str">\n];
}
1;
