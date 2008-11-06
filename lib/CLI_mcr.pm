#!/usr/bin/perl -wc
# Copyright (c) 1997-2004, Koji Omata, All right reserved
# Last update 2003/12/9
package CLI_mcr;
use strict;
use UDP_client;
use DB_mode;
use DB_cmd;

sub new($){
  my($pkg)=@_;
  my $this={};
  my $rmod= new DB_mode("mcr","[command]");
  my %mpar=$rmod->getmpar;
  $this->{udp}=new UDP_client($mpar{host},$mpar{port});
  $this->{rcmd}=new DB_cmd($mpar{mode},$mpar{usage});
  $this->{rprt}=new SYS_stdio;
  bless $this;
}

### Set and Get Status for FST
sub setcmd($$){
    my ($this,$cmd)=@_;
    $this->{rcmd}->setkey($cmd);
    my ($stat)=();
    $this->{udp}->snd($cmd);
    while($stat !~ /MCREND/){
	$stat=$this->{udp}->rcv;
	print $this->{rprt}->color($stat)."\n";
	if($stat =~ /\?/){
	    my $input=<STDIN>;
	    $this->{udp}->snd($input);
	}elsif($stat =~ /Execute/){
	    (my $flg,$cmd)=$this->{udp}->rcvsel('STDIN');
	    if($flg =~ /STDIN/){
		$this->{udp}->snd($cmd);
	    }else{
		print "$cmd\n";
	    }
	}    
    }
}
1;
