#!/usr/bin/perl -wc
# Copyright (c) 1997-2008, Koji Omata, All right reserved
# Last update:
# 2008/8/6 ENV{LOG}=SQL -> ENV{LOGSQL}=(hostname)
# 2007/9/13 Add port setting for MySql5
# 2006/7/21 Add Skip restriction
# 2005/11/13 Add warning message
# 2005/9/27 Effective if ENV{SQL_LOG} exists
# 2004/12/9
package SYS_sql;
use strict;
use DBI;
use DB_mode;
use DB_stat;
use MTN_ver;

sub new($$){
    my($pkg,$mode)=@_;
    my $this={table=>"log_$mode",mode=>$mode,rec=>"",
    port=>"3306",user=>"ciax",
    pass=>"rs232c",dbname=>"devlog"};
#    my $rsql=new DB_shared("db_mysql.txt");
    bless $this; 
#    return $this unless($rsql->setkey($ENV{PROJECT}));
    return $this unless($ENV{LOGSQL});
    $this->{host}=$ENV{LOGSQL};
    $this->{exec}=1;
#    $this->{host}=$rsql->getdb("host");
#    $this->{user}=$rsql->getdb("user");
#    $this->{pass}=$rsql->getdb("pass");
#    $this->{dbname}=$rsql->getdb("db");
    $this->{rst}=new DB_stat($mode);
    $this->{rver}=new MTN_ver("SQL%5","sql");
    $this->{module}=(`uname`=~ /SunOS/)?"mysqlPP":"mysql";
    return $this;
}

sub opendb($){
    my($this)=@_;
    return unless($this->{exec});
    my $options="$this->{dbname};host=$this->{host};port=$this->{port}";
    my $connect="DBI:$this->{module}:$options";
    $this->{rver}->statprt("connecting $connect");
    $this->{dbh} = DBI->connect($connect,$this->{user},$this->{pass});
    if($this->{dbh} eq ""){
	unless($this->createdb){
	    $this->{exec}="";
	    $this->{rver}->statprt("connection failed");
	    return;
	}
    }
    $this->{rver}->statprt("START SQL_LOG ($->{dbname})");
    return 1;
}

sub closedb{
    my($this)=@_;
    return unless($this->{exec});
    $this->{rver}->statprt("disconnect");
    $this->{dbh}->disconnect;
    $this->{rver}->statprt("Close SQL_LOG");
}    

sub doit($$){
    my($this,$str)=@_;
    return unless($this->{exec});
    $this->{rver}->statprt($str);
    $this->{dbh}->do($str);
}

sub sel($){
    my($this)=@_;
    return unless($this->{exec});
    my $select="SELECT * FROM $this->{table};";
    my $sth= $this->{dbh}->prepare($select);
    $sth->execute;
    while(my $data = $sth->fetchrow_arrayref()){
	print join(':',@$data),"\n";
    }
    $sth->finish;
}

sub droptable($){
    my($this)=@_;
    return unless($this->{exec});
    return if($this->{err});
    return ("DROP TABLE $this->{table};");
}

sub createdb($){
    my($this)=@_;
    return unless($this->{exec});
    $this->{dbh} = DBI->connect("DBI:$this->{module}::$this->{host}",$this->{user},$this->{pass}) || return;
    $this->{dbh}->do("CREATE DATABASE $this->{dbname};") || return;
    $this->{dbh}->do("USE $this->{dbname};") || return;
    $this->{rver}->warning("New DB $this->{dbname} is created");
    return 1;
}    

sub dropdb($){
    my($this)=@_;
    return unless($this->{exec});
    $this->{dbh}-> DBI->connect("DBI:mysql::$this->{host}");
    $this->{dbh}->do("DROP DATABASE $this->{db};");
    $this->{dbh}->disconnect;
}

sub rec($$){
    my ($this,$stat)=@_;
    return unless($this->{exec});
    return if($this->{rec} eq $stat and $ENV{LOG}=~/SKIP/);
    $this->{rec}=$stat;
    $this->{rst}->setdef($stat);
    $this->opendb;
    unless($this->doit($this->{rst}->sqlinsert)){
	$this->doit($this->{rst}->sqlcreate);
	unless($this->doit($this->{rst}->sqlinsert)){
	    $this->{exec}="";
	    $this->closedb;
	    return;
	}
    }
    $this->closedb;
}
1;
