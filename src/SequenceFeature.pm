package SequenceFeature;


# Stripped down sequence feature - no db access, no assembly version,  no parsing etc

sub new {
    my $caller = shift;

    my $class = ref($caller) || $caller;

    #print "new feature @_\n";
    my ($chr,$type1,$type2,$start,$end,$score,$strand,$phase,$hitid,$full_len,$seq) = rearrange(['CHR',
											    'TYPE1',
											    'TYPE2',
											    'START',
											    'END',
											    'SCORE',
											    'STRAND',
											    'PHASE',
											    'HITID',
											    'FULL_LEN',
											    'SEQ',
									       ],@_);
    

    
    if (defined($strand)) {
      if ($strand eq "+") {
	$strand = 1;
      }
      if ($strand eq "-") {
	$strand = -1;
      }
      if ( !($strand ==  1)  && 
	   !($strand == -1) && 
	   !($strand == 0)) {
	#throw('-STRAND argument must be 1, -1, or 0');
      }
    }
    
    if (defined($start) && defined($end)) {
      if($end+1 < $start) {
	#throw('Start must be less than or equal to end+1');
      }
    }
    
    
    return bless({'chr'      => $chr,
		  'type1'    => $type1,
		  'type2'    => $type2,
		  'start'    => $start,
		  'end'      => $end,
		  'score'    => $score,
		  'strand'   => $strand,
		  'phase'    => $phase,
		  'hitid'    => $hitid,
		  'full_len' => $full_len,
		  'seq'      => $seq,
		 }, $class);
}

sub chr {
    my $self = shift;
    $self->{'chr'} = shift if (@_);
    return $self->{'chr'};
}
sub start {
    my $self = shift;
    $self->{'start'} = shift if(@_);
    return $self->{'start'};
}
sub end {
    my $self = shift;
    $self->{'end'} = shift if(@_);
    return $self->{'end'};
}

sub type1 {
    my $self = shift;
    $self->{'type1'} = shift if(@_);
    return $self->{'type1'};
}

sub type2 {
    my $self = shift;
    $self->{'type2'} = shift if(@_);
    return $self->{'type2'};
}
sub score {
    my $self = shift;
    $self->{'score'} = shift if(@_);
    return $self->{'score'};
}
sub strand {
    my $self = shift;
    $self->{'strand'} = shift if(@_);
    return $self->{'strand'};
}
sub phase {
    my $self = shift;
    $self->{'phase'} = shift if(@_);
    return $self->{'phase'};
}
sub hitid {
    my $self = shift;
    $self->{'hitid'} = shift if(@_);
    return $self->{'hitid'};
}
sub seq {
    my $self = shift;
    $self->{'seq'} = shfit if (@_);
    return $self->{'seq'};
}

sub full_len {
  my $self = shift;
  $self->{'full_len'} = shift if (@_);
  return $self->{'full_len'};
}
  
sub hit_feature {
    my $self = shift;

    if (@_) {
      my $f = shift;
      $self->{hitid}      = $f->chr;
      $self->{hitfeature} = $f;
    }
	
    return $self->{hitfeature};
}

sub to_string {
    my $self = shift;

    my $str =  $self->{chr} . "\t" . 
    $self->{type1}  . "\t" . 
    $self->{type2}  . "\t" . 
    $self->{start}  . "\t" .
    $self->{end}    . "\t" .
    $self->{score}  . "\t" .
    $self->{strand} . "\t" . 
    $self->{phase};

    if ($self->hit_feature()) {
      my $f = $self->hit_feature;

      $str .= "\t" . $f->chr . "\t" .$f->start . "\t" . $f->end . "\t". $f->strand ;
    } elsif ($self->hitid) {
      $str .= "\t" . $self->hitid;
    }
    return $str;
}

sub clone {
    my ($f) = @_;

    if (!$f->isa("SequenceFeature")) {
	print "ERROR:  Feature must be a sequence feature to clone\n";
	exit(0);
    }

    my $newf = new SequenceFeature(-chr      => $f->chr,
				   -type1    => $f->type1,
				   -type2    => $f->type2,
				   -start    => $f->start,
				   -end      => $f->end,
				   -score    => $f->score,
				   -phase    => $f->phase,
	);

    if ($f->hitid) {
	$newf->hitid($f->hitid);
    }

    if ($f->hit_feature) {
	# Do I want to clone this?
	$newf->hit_feature($f->hit_feature);
    }

    return $newf;
}

sub length {
  my ($self) = @_;

  return ($self->end-$self->start+1);
}

sub new_from_gff_string {
    my ($str) = @_;

    chomp($str);

    my @f = split(/\t/,$str);

    my $sf = new SequenceFeature(-chr   => $f[0],
				 -type1 => $f[1],
				 -type2 => $f[2],
				 -start => $f[3]+1,
				 -end   => $f[4],
				 -strand => $f[5],
				 -score  => $f[6],
				 -phase  => $f[7]);

    if (defined($f[8])) {
	$sf->hitid($f[8]);
    }
    if (defined($f[9])) {
	$sf->seq($f[9]);
    }
    return $sf;
}				 

sub rearrange {
  my $order = shift;

  # Convert all of the parameter names to uppercase, and create a
  # hash with parameter names as keys, and parameter values as values
  my $i = 0;

  # when i is 0 print the uppercase key
  # when i is 1 print just the value.

  my (%param) = map {if ($i) { $i--; $_; } else { $i++;uc($_); }} @_;

  # What we intend to do is loop through the @{$order} variable,
  # and for each value, we use that as a key into our associative
  # array, pushing the value at that key onto our return array.

  # Print out the param values in the @$order order
  return map {$param{uc("-$_")}} @$order;
}

1;
