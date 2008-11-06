#!/usr/bin/perl -wc
# Last update 2002/7/24
package CFG_set_nt;
use SYS_file;
use DB_stat;
use CFG_html_frm;

sub new($$){
  my($pkg,$mode)=@_;
  my $this={};
  my %obj=(nct=>"W",nso=>"O",nsi=>"I");
  $mode="nct" unless($mode);
  $this->{sdb}=new DB_stat($mode,"NT",1);
  $this->{fsp}=new SYS_file("resp$obj{$mode}.nt","n");
  $this->{html}=new CFG_html_frm($mode,$0);
  $this->{title}=uc($mode)." STATUS";
  $this->{mode}=$mode;
  bless $this;
}

sub setstat($$){
  my($this,$data)=@_;
  print $this->{html}->cgi_header($this->{title});
  print $this->{html}->headline(1,$this->{title});
  if($data eq ""){
    $this->formstat;
  }else{
    $this->{fsp}->wri($data);
    $this->prttbl($data);
    print $this->{html}->gohome;
  }
  print $this->{html}->cgi_footer;
}

sub formstat($){
  my($this)=@_;
  print $this->{html}->frm_head;
  $this->prtfrm($this->{fsp}->red);
  print $this->{html}->frm_submit;
}

sub viewstat($){
  my($this)=@_;
  $this->prttbl($this->{fsp}->red);
}

################  Html subroutine ##############
sub prtfrm($$){
  my ($this,$stat)=@_;
  $this->prthtml("frm",$stat);
}

sub prttbl($$){
  my ($this,$stat)=@_;
  $this->prthtml("tbl",$stat);
}

sub prthtml($$$){
    my ($this,$key,$stat)=@_;
    $this->{sdb}->setdef("%DMY".$stat);
    my @rec=($key eq tbl)?$this->{sdb}->table : $this->{sdb}->form;
    ####  Html Output ####
    print $this->{html}->tbl_head;
    foreach my $line (@rec){
	my @tds=();
	foreach(split(/,/,$line)){
	    my($name,$sym,$opt)=split(/;/);
	    push @tds,$name;
	    if($key eq "frm"){
		push @tds,$this->{html}->frm_select($sym,$opt); 
	    }elsif($key eq "tbl"){
		push @tds,$sym;
	    }
	}
	print $this->{html}->tbl_line(@tds);
    }  
    print $this->{html}->tbl_end;
}
1;
