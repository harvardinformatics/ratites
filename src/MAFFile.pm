package MAFFile;

use vars qw(@ISA);
use strict;
use FileHandle;
use SequenceFeature;
use Data::Dumper;
use MAFSlicer;

sub new {
    my ($class) = shift;

    my ($reforg,$file) = rearrange(['REFORG','FILE'],@_);

    my $self = {
	reforg    => $reforg,
	file      => $file,
    };

    bless $self, $class;

    return $self;

}

sub get_reforg_from_file {
    my ($self) = @_;

    my $file = $self->{file};

    my $fh = new FileHandle();
    $fh->open("<$file");

    while (my $line = <$fh>) {
	if ($line =~ /^a +score/) {
	    my $idline = <$fh>;
	    my $id = $idline;
	    if ($id =~ /^s +(\S+).*/) {
		$id =~ s/^s +(\S+).*/$1/;
		$fh->close();
		return $id;
	    } else {
		print "ERROR: Line following a score line should start with a. We have\n$line\n$idline\n";
		exit(0);
	    }
	}
    }
    $fh->close();
}

sub get_reforg {
    my ($self) = @_;

    if (! defined($self->{reforg})) {
	$self->{reforg} = $self->get_reforg_from_file();
    }
    return $self->{reforg};
}

sub get_ref_gff {
    my ($self) = @_;

    my $file = $self->{file};

    my $fh = new FileHandle();
    $fh->open("<$file");

    my @gff;

    while (my $line = <$fh>) {
	chomp($line);
	if ($line =~ /^a +score=(\S+)/) {
	    my $score   = $1;
	    my $refline = <$fh>;

	    chomp($refline);

	    my @f = split(' ',$refline);

	    my $id   = $f[1];
	    my $chr  = $id;
	    my $type = "maf";

	    if ($id =~ /(\S+)\.(\S+)/) {
		$chr = $2;
	    }

	    my $start  = $f[2];
	    my $len    = $f[3];
	    my $strand = $f[4];
	    my $chrlen = $f[5];
	    my $seq    = $f[6];

	    my $sf = new SequenceFeature(-chr      => $chr,
					 -type1    => $type,
					 -type2    => 'maf',
					 -start    => $start,
					 -end      => ($start+$len),
					 -score    => $score,
					 -strand   => $strand,
					 -phase    => ".",
					 -full_len => $chrlen,
					 -seq      => $seq);

	    push(@gff,$sf);
	}
    }
    return @gff;
}

sub sort {
    my ($self,$overwrite) = @_;

    my $file = $self->{file};

    my @headers;
    my $foundaln = 0;
    
    print STDERR "Sorting maf file $file\n";

    my $fh = new FileHandle;
    $fh->open("<$file");
    
    my $line;
    my @pieces;
    
    while ($line = <$fh>) {
	
	if ($line =~ /^a +/) {
	    $foundaln = 1;
	    my %tmppiece;
	    push(@{$tmppiece{'lines'}},$line);
	    
	    $line = <$fh>;
	    
	    push(@{$tmppiece{'lines'}},$line);
	    
	    if ($line =~ /^s +(\S+) +(\S+) +(\S+) +(\S+) +(\S+)/) {
		$tmppiece{'chr'}   = $1;
		$tmppiece{'start'} = $2;
	    }
	    while ($line = <$fh>) {
		last if $line =~ /^\n$/;
		push(@{$tmppiece{'lines'}},$line);
	    }
	    push(@pieces,\%tmppiece);
	} elsif ($line =~ /^#/ && !$foundaln) {
	    push(@headers,$line);
	}
    }
    
    my @newpieces = sort {$a->{start}<=>$b->{start}} @pieces;
    
    $fh->close();

    my $fh = new FileHandle();

    if (!$overwrite) {
	$fh->open(">$file.new");
    } else {	
	system("mv $file $file.orig");
	$fh->open(">$file");
    }
    foreach my $header (@headers) {
	print $fh $header;
    }
    
    foreach my  $piece (@newpieces) {
	foreach my $line (@{$piece->{'lines'}}) {
	    print $fh $line;
	}
	print $fh "\n";
    }
    $fh->close();
}

sub get_alignment_region {
    my ($self,$chr,$start,$end) = @_;

    print "Getting for $chr $start $end\n";

    my $mafslicer = new MAFSlicer(-reforg  => $self->{reforg},
				  -maffile => $self,
				  -debug   => 0);

    my $aln = $mafslicer->get_align($chr,$start,$end);

    return $aln;
}


sub index {
    my ($self,$overwrite) = @_;

    my @pieces;

    my $alnfile = $self->{file};
    my $idxfile = "$alnfile.index";

    if (! -e $idxfile || $overwrite) {
	print STDERR "Indexing alignment file $alnfile to $idxfile\n";

	my $fh = new FileHandle;
	$fh->open("<$alnfile");
		    
	open(OUT,">$idxfile");

	my $line;
	my $pos = tell($fh);
	my $prev;
	my %orgs;

	while ($line = <$fh>) {
	    
	    if ($line =~ /^a +/) {
		$pos = tell($fh) - length($line);
		$line = <$fh>;
		
		if ($line =~ /^s +(\S+) +(\S+) +(\S+) +(\S+) +(\S+)/) {
		    
		    print OUT $2 . "\t" . $3 . "\t" . ($pos) . "\n";

		    # Add into the orgs hash
		    my $chrlen = $5;
		    my $tmporg = $1;
		    
		    if (!$self->{reforg}) {
			$self->{reforg} = $tmporg;
		    }
		    
		    if ($tmporg =~ /(\S+)\.(\S+)/) {
			$orgs{$1}{$2} = $chrlen;
		    }
		    
		} else {
		    print STDERR "Unrecognized line $line\n";
		}
		
	    } elsif ($line =~ /^s +(\S+) +(\S+) +(\S+) +(\S+) +(\S+)/) {
		# Add into the orgs hash
		
		my $chrlen = $5;
		my $tmporg = $1;
		
		if ($tmporg =~ /(\S+)\.(\S+)/) {
		    $orgs{$1}{$2} = $chrlen;
		}
	    }
	    $pos = tell($fh);
	}
	
	close(OUT);
	$fh->close();

	# Now write the orgfile for this maf

	my $orgfile = $alnfile . ".orgs";

	my $fh = new FileHandle();

	$fh->open(">$orgfile");

	foreach my $org (keys %orgs) {
	    $fh->print("$org\n");
	}

	$fh->close();
    }
    return;
}

sub get_orgs {
    my ($self) = @_;

    my $orgfile = $self->{file} . ".orgs";

    if (!defined($self->{orgs})) {
	my @orgs;

	if (! -e $orgfile) {
	    $self->index(1);
	}

	my $fh = new FileHandle();
	$fh->open("<$orgfile");

	while (<$fh>) {
	    chomp;
	    push(@orgs,$_);
	}
	$fh->close();
	$self->{orgs} = \@orgs;

	if (scalar(@{$self->{orgs}}) == 0) {
	    print ("ERROR: No orgs found in orgfile [$orgfile]");
	}
    }
    return @{$self->{orgs}};
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
