package UCSCGenome;

use vars qw(@ISA);
use strict;
use FileHandle;
use SequenceFeature;
use BSearch;
use GFFFile;
use Data::Dumper;

sub new {
    my ($class) = shift;

    my ($reforg) = rearrange(['REFORG'],@_);

    my $genomedir = "/Users/mclamp/data/ucsc/goldenPath/$reforg/";

    my $self = {
	reforg    => $reforg,
	genomedir => $genomedir,
	maffiles  => {}
    };

    bless $self, $class;

    return $self;

}

sub get_gene_gff_region {
    my ($self,$chr,$start,$end,$offset) = @_;
    
    my $reforg    = $self->{reforg};

    my $infile    = $self->{genomedir} . "database/ensGene.startsorted.gff";

    if (! -e $infile) {
	print "ERROR: Gene gfffile [$infile] doesn't exist\n";
	exit(0);
    }
    my $gfffile = new GFFFile(-file => $infile,
			      -reforg => $reforg);
    my @gff = $gfffile->get_region($chr,$start,$end,$offset);
    
    return @gff;
}


sub get_alignment_region {
    my ($self,$chr,$start,$end) = @_;

    if (! defined($self->{maffiles}{$chr})) {
	my $maffilename = "/Users/mclamp/Downloads/maf/$chr.maf";
	#my $maffilename = $self->{genomedir} . "multiz7way/$chr.maf";
	print "Making maffile $maffilename\n";
	$self->{maffiles}{$chr} = new MAFFile(-reforg => $self->{reforg}, -file => $maffilename);
    }
    
    return $self->{maffiles}{$chr}->get_alignment_region($chr,$start,$end);

}

sub get_refseq_region {
    my ($self,$chr,$start,$end) = @_;

    my $nib = $self->{genomedir} . "/bigZips/$chr.fa.nib";
    
    $start--;

    if (! -e $nib) {
	print "ERROR: Can't find nib file $nib\n";
	return;
    }
    my $cmd = "/Users/mclamp/bin/x86_64/nibFrag -masked -name=$chr.$start-$end $nib $start $end + stdout |";

    my $fh = new FileHandle();
    $fh->open("$cmd");

    my $seq;

    while (<$fh>) {
	if ($_ !~ /^>/) {
	    chomp;
	    $seq .= $_;
	}
    }
    return $seq;
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
