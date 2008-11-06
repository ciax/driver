#!/usr/bin/perl -wc
# Last update 2003/5/23
package CFG_cgi;

sub new($){
  my($pkg)=@_;
  my $this={};
  bless $this;
}
################# For CGI Header ###################
sub getpar($){
  my($this)=@_;
  my $str=$this->setdat;
  my %db=$this->decode($str);
  foreach(@ARGV){
      my($key,$val)=split("=",$_);
      next unless($val);
      $db{$key}=$val;
  }
  return %db;
}

sub sortpar($){
  my($this)=@_;
  my %form=$this->getpar;
  my @rslt=();
  push @rslt,$form{$_} foreach (sort keys %form);
  return @rslt;
}

# POST or ENV
sub setdat($){
  my($this)=@_;
  my $string=undef;
  if ($ENV{'REQUEST_METHOD'} eq "POST") {
    read (STDIN,$string,$ENV{'CONTENT_LENGTH'});
  } elsif ($ENV{'REQUEST_METHOD'} eq "GET") {
    $string = $ENV{'QUERY_STRING'};
  }
  return $string;
}

# GET and Decode paramater
sub decode($$){
  my ($this,$data)=@_;
  my @pairs = split(/&/,$data);
  foreach (@pairs){
    my ($name,$value) = split(/=/);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
    $value =~ s/&lt;/&lt;/g;
    $value =~ s/&gt;/&gt;/g;
    $db{$name} = $value;
  }
  return %db;
}
1;
