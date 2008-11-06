#!/usr/bin/perl -wc
package CFG_set_jak;
use CFG_file_jak;
use CFG_html_frm;

sub new($$){
  my($pkg,$inst)=@_;
  my $this={};
  $this->{html}=new CFG_html_frm($inst,$0);
  $this->{jkf}=new CFG_file_jak($inst);
  $this->{inst}=$inst;
  bless $this;
}

############### Internal routine  #############

sub setstat($@){
  my ($this,@pars)=@_;
  print $this->{html}->cgi_header("JACK PULSE SET($this->{inst})");
  print $this->{html}->headline(1,"JACK PULSE SET($this->{inst})");
  if(! scalar @pars){
    print $this->{html}->frm_head;
    $this->prtfrm;
    print $this->{html}->frm_submit;
  }else{
    $this->{jkf}->mkjkval(@pars);
    $this->prttbl;
    print $this->{html}->gohome;
  }
  print $this->{html}->cgi_footer;
}

################  Html subroutine ##############

sub prtfrm($){
  my ($this)=@_;
  $this->prthtml("frm");
}
sub prttbl($){
  my ($this)=@_;
  $this->prthtml("tbl");
}

sub prthtml($$){
  my ($this,$key)=@_;
  print $this->{html}->headline(2,"For Summit (x1000)");
  print $this->{html}->tbl_head;
  my @insts=$this->{jkf}->jackval;
  my @idx=("TagName","LVJ1","LVJ2","LVJ3","LVJ4");
  my @num=(0..3);
  my @loca=();
  if($this->{inst} !~ /CHG/){
    push @idx,("UP1","UP2");
    push @num,(4..5);
    @loca=("CAS","MOV.OPT","FIX.OPT","MOV.IR","FIX.IR","OPSM");
  }else{
    @loca=("CHG.OPT","CHG.IR");
  }
  print $this->{html}->tbl_line(@idx);
  foreach my $l (@loca){
    my @line=($l);
    my ($inst)=grep(/$l/,@insts);
    my ($dmy,$dat)=split(/,/,$inst);
    chomp $dat;
    my @vals=split(/:/,$dat);
    foreach my $n (@num){
      push @line,$this->{html}->frm_text($vals[$n]) if($key eq "frm");
      push @line,$vals[$n] if($key eq "tbl");
    }
    print $this->{html}->tbl_line(@line);
  }  
  print $this->{html}->tbl_end;
}
1;

