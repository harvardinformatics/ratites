use strict;
use MAF;
use MAFFile;
use UCSCGenome;

use Getopt::Long;
use Data::Dumper;
use Cluster;

$| = 1;
my $maffile1;
my $maffile2;

my $reforg = 'galGal3';
my $stub   = "all";

&GetOptions("maffile1=s" => \$maffile1,
            "maffile2=s" => \$maffile2,
	    "stub=s"     => \$stub,
            "reforg=s"   => \$reforg);

my $maffile1 = new MAFFile(-file => $maffile1,-reforg => $reforg);
my $maffile2 = new MAFFile(-file => $maffile2, -reforg => $reforg);

$maffile1->sort();
$maffile2->sort();

$maffile1->index();
$maffile2->index();

my $reforg1  = $maffile1->get_reforg();
my $reforg2  = $maffile2->get_reforg();


if ($reforg1 != $reforg2) {
    print "ERROR: Reference orgs arent' the same [$reforg1] [$reforg2]\n";
    exit(0);
}

my @gff1     = $maffile1->get_ref_gff();
my @gff2     = $maffile2->get_ref_gff();

foreach my $gff (@gff2) {
    push(@gff1,$gff);
}

my ($chr,$start,$end) = get_best_region(@gff1);

print "Best region is $chr - $start-$end\n";
    
    
my $genome = new UCSCGenome(-reforg => $reforg1);

print "Got genome\n";
    
my @genegff = $genome->get_gene_gff_region($chr,$start,$end,1);

##### Extract region for maffile 1 and 2

my $aln1 = $maffile1->get_alignment_region($chr,$start,$end);


my $aln2 = $maffile2->get_alignment_region($chr,$start,$end);


##### Extract region for vertebrate alignment

my $refaln = $genome->get_alignment_region($chr,$start,$end);


foreach my $org (keys %$aln1) {
    if ($org ne $reforg) {
	$refaln->{$org} = $aln1->{$org};
    }
}
foreach my $org (keys %$aln2) {
    if ($org ne $reforg) {
	$refaln->{$org} = $aln2->{$org};
    }
}

##### Combine into one file, sort and dedup

my $outfile = $reforg .".$stub.fa";
my $outfh  = new FileHandle();
$outfh->open(">$outfile");


##### Get the reference seq for this region


#my $refseq = $refaln->{$reforg};
#print $outfh ">$reforg.$chr:$start-$end\n";
#$refseq =~ s/(.{72})/$1\n/g;
#print $outfh $refseq ."\n";

my $refseq = $genome->get_refseq_region($chr,$start,$end);

print $outfh ">$reforg.$chr:$start-$end\n";
$refseq =~ s/(.{72})/$1\n/g;
print $outfh $refseq ."\n";

my @neworgs = sort_orgs_by_coverage($refaln,$reforg,keys(%$refaln));

foreach my $org (@neworgs) {
    if ($org ne $reforg) {
	my $seq = $refaln->{$org};
	print $outfh ">$org\n";
	$seq =~ s/(.{72})/$1\n/g;
	print $outfh $seq ."\n";
    }
}

$outfh->close();

my $outfile = $reforg . ".$stub.gff";
my $outfh = new FileHandle();
$outfh->open(">$outfile");

foreach my $gff (@genegff) {
    print $outfh $gff->to_string() . "\n";
}

$outfh->close();


sub sort_orgs_by_coverage {
    my ($fullstr,$reforg,@orgs) = @_;
    
    my %cov;

    my $fulllen = length($fullstr->{$reforg});

    foreach my $org (@orgs) {
	my $tmpseq = $fullstr->{$org};
	my $count = ($tmpseq =~ tr/ATGC//);
	$cov{$org} = $count;
	print "ORG $org $count $fulllen\n";
    }

    my @neworgs = sort {$cov{$b} <=> $cov{$a}} @orgs;

    return @neworgs;
}

sub get_best_region {
    my (@gff) = @_;

    @gff = sort {$a->{start} <=> $b->{start}} @gff;
    
    print "Got " . scalar(@gff) . " gff features\n";
    
    my @clus = Cluster::cluster_sorted_features(\@gff,10000);
    
    print "Got " . scalar(@clus) . " gff clusters\n";
    
    @clus = sort { $b->length() <=> $a->length() } @clus;
    
    foreach my $clus (@clus) {
	print $clus->{chr} . "\t" . $clus->{start} . "\t" . ($clus->{end}-$clus->{start}) . "\t". scalar(@{$clus->{features}}) ."\n";
    }

    my $topclus = $clus[0];

    my $chr   = $topclus->{chr};
    my $start = $topclus->{start};
    my $end   = $topclus->{end};
    
    return ($chr,$start,$end);
}

