package GFFFile;

use vars qw(@ISA);
use strict;
use FileHandle;
use SequenceFeature;
use BSearch;
use Data::Dumper;

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

sub get_region {
    my ($self,$chr,$start,$end,$offset) = @_;
    
    $start--;

    my $field = 3;
    my $fh    = BSearch::search_file($self->{file},$start,$field);
    
    my $line;
    
    my @gff;

    while ($line = <$fh>) {
#	print $line;
	chomp($line);

	my $gff = SequenceFeature::new_from_gff_string($line);

	if ($gff->{chr} eq $chr) {
	    print STDERR "Found $chr\n";
	    
	    if (!($gff->start > $end    ||
		  $gff->end   < $start)
		) {
		if ($offset) {
		    $gff->start($gff->start - $start);
		    $gff->end  ($gff->end   - $start);
		}
		push(@gff,$gff);
	    }
	}
	if ($gff->start > $end) {
	    last;
	}
    }


    $fh->close();
    return @gff;
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
