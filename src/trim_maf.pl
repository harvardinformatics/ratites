use strict;
use MAF;

use Getopt::Long;
use Data::Dumper;

my $infile;

&GetOptions("infile=s" => \$infile);

my $maf = new MAF(-dir => "./",-reforg=>'galGal3');
$maf->read_orgfile();

my $fh = new FileHandle();

$fh->open("<$infile");

my %piece;
my %prevpiece;

my @orgs = $maf->get_orgs();

while (%piece = $maf->read_piece($fh)) {

   # $maf->print_piece(\%piece);
    my $gap = 0;
    if (%prevpiece) {
	$gap = $piece{'galGal3'}{start} - $prevpiece{'galGal3'}{end};
	#print "GAP $gap\n";
    }

    if ($gap < 0) {
	my $trimstart = -1*$gap;
	my $tmppiece = $maf->trim_piece(\%piece,$trimstart,0,"galGal3",$piece{'galGal3'}{start});

#	$maf->print_piece($tmppiece);
	%piece = %$tmppiece;
    }

#    print Dumper(\%piece);

    my $str = $maf->piece_to_maf(\%piece);
    print $str;
    %prevpiece = %piece;
}
