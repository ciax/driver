#!/usr/bin/perl
# Last update 2003/10/2
package CFG_graph;
use GD::Graph::lines;
use DB_mode;
use DB_stat;

sub new($$$$){
    my($pkg,$mode,$offset,$length,$chnls)=@_;
    $length=($length<16)?2**$length*144:$length;
    $offset=0 if($offset<0);
    my $this={mode=>$mode,offset=>$offset,length=>$length,skip=>$length/12};
    $this->{rmod}=new DB_mode($mode," ");
    my %mpar=$this->{rmod}->getmpar;
    $this->{rst}=new DB_stat($mode,$mpar{caption});
    $this->{title}=$mpar{caption};
    my $tail=$offset+$length;
    my @logl=`cat $ENV{DRVVAR}/log/$mode\*.log|tail -n $tail`;
    chomp @logl;
    @{$this->{logl}}=sort(grep(/_00_/,@logl));
#    @{$this->{logl}}=grep(!/(\?\+9999|.*_00E)/,@logl);
    if($chnls=~/[0-9]/){
	@{$this->{ch}}=map("ch$_",split(",",$chnls));
    }else{
	@{$this->{ch}}=grep(/ch[0-9]/,$this->{rst}->getkeys);
    }
    push @{$this->{legend}},$this->{rst}{sym}{$_}{caption} foreach (@{$this->{ch}});
    bless $this;
}

sub printgraph($){
    my($this)=@_;
    my $mode=$this->{mode};
    my $gdb=new DB_shared('db_graph.txt');
    $gdb->setkey($mode);
    my $y_label=$gdb->getdb("y_label");
    my $y_max=$gdb->getdb("y_max");
    my $y_min=$gdb->getdb("y_min");
    my $y_tick=$gdb->getdb("y_tick") || 6;
    ($y_max,$y_min)=(undef,undef) unless($y_max=~/\d/ and $y_min=~/\d/);
    my $log10=$gdb->getdb("log10");
    my @data=$this->_getdata($log10);
    my $graph = GD::Graph::lines->new(640,480);
    my %par=(
	title=>$this->{title},
	x_lavel=>'DATE',
	y_label=>$y_label,
	long_ticks=>1,
	tick_length=>0,
	tickclr=>'black',
	y_max_value=>$y_max,
	y_min_value=>$y_min,
	fgclr=>'lgray',
	transparent=>1,
	shadowclr=>'gray',
	shadow_depth=>10,
	line_types=>[1,2,3,4],
	line_width=>2,
	dclrs=>[blue,red,green,yellow,orange,pink,purple,cyan],
	y_tick_number=>$y_tick,
	y_label_skip=>2,
	x_label_skip=>$this->{skip},
	x_labels_vertical=>1,
	zero_axis=>1,
    );
    $graph->set(%par);
    $graph->set_legend(@{$this->{legend}});
#    $graph->set_legend_font('/usr/share/enlightenment/themes/ShinyMetal/ttfonts/rothwell.ttf',18);
    return $graph->plot(\@data)->png;
}

################ Internal #################
sub _getdata($$){
    my($this,$log10)=@_;
    my ($dly,@data,$day0)=($this->{skip});
    $log10=log(10) if($log10);
    for(my $i=0;$i<$this->{length};$i++){
	my $pointer=$i-$this->{offset}-$this->{length};
	my($date,$stat)=unpack("A14A*",$this->{logl}[$pointer]);
	next if($stat!~/^%/);
	my $num=0;
	my($y,$m,$d,$a0,$hr,$min,$s)=unpack("A2A2A2AA2A2A2",$date);
	my $dstr="$m/$d($hr:$min:$s)";
	if($day0 ne $day){
	    $dstr="$m/$d";
#	    if($dly--<=2){
		$day0=$day;
#		$dly=$this->{skip};
#	    }
	}
	$data[$num++][$i]=$dstr;
	$this->{rst}->setdef($stat);
	foreach (@{$this->{ch}}){
	    my $val=$this->{rst}->getsym($_);
	    if($log10){
		if($val>0){
		    $val=log($val)/$log10;
		}else{
		    $val=1;
		}
	    }
	    $data[$num++][$i]=$val;
	}
    }
    return @data;
}
1;
