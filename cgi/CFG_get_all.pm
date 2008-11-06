#!/usr/bin/perl -wc
# Last update 2006/3/21 Print -> Return Strings
# 2003/2/27
package CFG_get_all;
use DB_mode;
use DB_stat;
use CFG_html;
use CLI_cmd;

sub new($$){
  my($pkg,$mode)=@_;
  my $this={mode=>$mode};
  $this->{rmod}=new DB_mode($mode," ");
  my %mpar=$this->{rmod}->getmpar;
  $this->{rst}=new DB_stat($mode,$mpar{caption});
  $this->{title}=$mpar{caption};
  $this->{html}=new CFG_html;
  bless $this;
}

sub viewstat($){
  my($this)=@_;
  my $rcom=new CLI_cmd($this->{rmod}->getmpar);
  my $stat=$rcom->setcmd("stat");
  return $this->prttbl($stat);
}

################  Html subroutine ##############
sub prttbl($$){
    my ($this,$stat)=@_;
    $this->{rst}->setdef($stat);
    my @table=$this->{rst}->table;
    my $print=$this->{html}->headline(2,$this->{title});
    $print.=$this->{html}->tbl_head;
    foreach(@table){
	my @tds=();
	foreach(split(/,/)){
	    my ($caption,$sym,$opt)=split(/;/);      
	    push @tds,$caption,$sym;
	}
	$print.=$this->{html}->tbl_line(@tds);
    }  
    return $print.$this->{html}->tbl_end;
}
1;
