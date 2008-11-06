#!/usr/bin/perl -wc
package CFG_set_tag;
use CFG_file_tag;
use CFG_html_frm;

sub new($){
  my($pkg)=@_;
  my $this={};
  $this->{html}=new CFG_html_frm("tag",$0);
  bless $this;
}

############### Internal routine  #############
sub setstat($@){
  my($this,@pars)=@_;
  print $this->{html}->cgi_header("CIAX TAG ADDRESS SET");
  print $this->{html}->headline(1,"CIAX TAG ADDRESS SET");
  if(shift @pars){
    my $tg= new CFG_file_tag;
    $tg->stat2file(@pars);
    $this->prttbl;
    print $this->{html}->gohome;
  }else{
    print $this->{html}->frm_head;
    $this->prtfrm;
    print $this->{html}->frm_submit;
  }
  print $this->{html}->cgi_footer;
}

################  Html subroutine ##############

sub prtfrm($){
  my($this)=@_;
  $this->prthtml("frm");
}
sub prttbl($){
  my($this)=@_;
  $this->prthtml("tbl");
}

sub prthtml($$){
  my($this,$key)=@_;
  my $tg=new CFG_file_tag;
  my @stat=$tg->file2stat;
  my @caption=("Tag");
  push @caption,"Bit$_" foreach(0..7);
  push @tgtag,"Tag$_" foreach(1..12);
  print $this->{html}->headline(2,"For Summit ");
  print $this->{html}->tbl_head;
  print $this->{html}->tbl_line(@caption);
  foreach (@tgtag){
    my @line=($_);
    foreach(0..7){
      my $data=shift @stat;
      push @line,$this->{html}->frm_selbin($data) if($key eq "frm");
      push @line,$data if($key eq "tbl");
    }
    print $this->{html}->tbl_line(@line);
  }  
  print $this->{html}->tbl_end;
}
1;
