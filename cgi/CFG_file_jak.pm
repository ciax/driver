#!/usr/bin/perl -wc
# Last update 2002/7/24
package CFG_file_jak;
use SYS_file;

sub new($$){
  my($pkg,$inst)=@_;
  my $this={};
  $this->{fsp}=new SYS_file("cartJak.txt","s");
  $this->{ins}=uc($inst);
  bless $this;
}

################### Local for Jack ###################

sub jackval($){
  my ($this)=@_;
  my @strs=$this->{fsp}->red;
  my @ins=grep(/$this->{ins}/,@strs);
  return @ins;
}

sub mkjkval($@){
  my ($this,@data)=@_;
  my @loca=("CAS","MOV.OPT","FIX.OPT","MOV.IR","FIX.IR","OPSM");
  @loca=("CHG.OPT","CHG.IR") if($this->{ins} =~ /CHG/);
  my $num=6;
  $num=4 if($this->{ins} =~ /CHG/);
  my @line=();
  foreach my $l (@loca){
    my @lvs=splice(@data,0,$num);
    my $lv=join(":",@lvs);
    push @line,"$this->{ins}:$l,$lv";
  }
  return $this->apndjak(@line);
}  

# Append Jack Data to status/cartJak.txt
sub apndjak($@){
  my ($this,@news)=@_;
  my @orgs=grep(!/$this->{ins}/,$this->{fsp}->red);
  $this->{fsp}->wri(sort (@orgs,@news));
}
1;
