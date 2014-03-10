use strict;
use MAF;

use Getopt::Long;
use Data::Dumper;

my $reforg;
my $mafdir;
my $orgdir = "/Users/mclamp/data/ucsc/goldenPath/galGal3/bigZips/";
my $overwrite;
my $chr;
my $start;
my $end;
my $sort  = 0;
my $debug = 0;

&GetOptions("reforg=s" => \$reforg,
	    "mafdir=s" => \$mafdir,
	    "overwrite"=> \$overwrite,
	    "sort"     => \$sort,
	    "debug"    => \$debug,
            "chr=s"    => \$chr,
            "start=i"  => \$start,
            "end=i"    => \$end);
	   
my $maf = new MAF(-reforg => $reforg,
		  -dir    => $mafdir,
		  -debug  => $debug,
                  -overwrite => $overwrite);

if ($sort) {
    $maf->sort();
}
$maf->init();
$maf->orgdir($orgdir);

my $refseq = $maf->get_region($chr,$start,$end);

my $aln  = $maf->get_align($chr,$start,$end);

my @orgs = $maf->sort_orgs_by_coverage();

foreach my $org (@orgs) {
    print STDERR $org . "\n";
}

my $refaln = $aln->{$reforg};

print ">$reforg.real\n";
$refseq =~ s/(.{72})/$1\n/g;
print $refseq . "\n";

if (defined($aln->{$reforg})) {
	print ">$reforg\n";
	my $str = $aln->{$reforg};
	$str = $maf->strip_gaps($refaln,$str);
	$str =~ s/(.{72})/$1\n/g;
	print $str . "\n";
}
foreach my $org (@orgs) {
    if ($org ne $reforg && defined($aln->{$org})) {
	print ">$org\n";
	my $str = $aln->{$org};
	$str = $maf->strip_gaps($refaln,$str);
	$str =~ s/(.{72})/$1\n/g;
	print $str . "\n";
    }
}

