#!/usr/bin/perl -wc
# Last update 2003/1/28
package CFG_file_tag;
use SYS_file;

sub new($){
  my($pkg)=@_;
  my $this={};
  $this->{fsp}=new SYS_file("setAdr.def","s");
  bless $this;
}

############### Internal ###############
sub bin2hex($$){
  my($this,$bin)=@_;
  return uc(unpack("H2",pack("b16",$bin)));
}
sub hex2bin($$){
  my($this,$hex)=@_;
  return unpack("b16",pack("H2",$hex));
}
################ Local for Tg ###############
sub file2stat($){
  my($this)=@_;
  my ($data)=$this->{fsp}->red;
  my @tmp1=unpack("A2"x12,substr($data,1));
  my @stat=();
  foreach (@tmp1){
    my $bin=$this->hex2bin($_);
    my @str=unpack("A"x8,$bin);
    push(@stat,@str);
  }
  return @stat;
}

sub stat2file($@){
  my($this,@stat)=@_;
  my $str=join("",@stat);
  my @stat2=unpack("A8"x12,$str);
  my $data="2";
  $data=$data . $this->bin2hex($_) foreach (@stat2);
  $this->{fsp}->wri($data);
}
1;
