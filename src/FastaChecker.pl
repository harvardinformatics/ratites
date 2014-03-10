package FastaChecker;

use vars qw(@ISA);
use strict;
use FileHandle;
use Data::Dumper;

sub new {
    my ($class) = shift;

    bless $self, $class;

    return $self;

}

sub check_fastafile_sequence {
    my ($file) = @_;

    my $fh = new FileHandle();
    $fh->open("<$file");

    my $id;
    my $seq;

    my %res;
    my @seqs;
    my @ids;

    while (<>) {
	chomp;
	my $line = $_;
	
	if ($line =~ /^>(\S+)/) {
	    my $tmpid = $1;

	    if (defined($id)) {
		$res{$id} = FastaChecker::check_sequence($seq);
		push(@ids,$id);
		push(@seqs,$seq);
	    }
	    
	    $id  = $tmpid;
	    $seq = "";
	} else {
	    $seq .= $line;
	}
    }

    return(\@ids,\@seqs,\%res);

}

sub check_sequence {
    my ($seq) = @_;

    $seq =~ s/[^AGTC\n\r]/N/g;

    return $seq;
}

sub get_sequence_stats {
    my ($id,$seq) = @_;

    my %stats;

    $stats{length} = length($seq);
    
    my $acount = ($seq =~ tr/A/A/);
    my $ccount = ($seq =~ tr/C/C/);
    my $gcount = ($seq =~ tr/G/G/);
    my $tcount = ($seq =~ tr/T/T/);

    my $maskedacount = ($seq =~ tr/a/a/);
    my $maskedccount = ($seq =~ tr/C/C/);
    my $maskedgcount = ($seq =~ tr/G/G/);
    my $maskedtcount = ($seq =~ tr/T/T/);

    my $ncount = ($seq =~ tr/N/N/);
    my $maskedncount = ($seq =~ tr/n/n/);

    my $tmpseq =~ s/[^ACGTacgtNn]//;
    my $othercount = length($tmpseq);

    $stats{acount} = $acount;
    $stats{ccount} = $ccount;
    $stats{gcount} = $gcount;
    $stats{tcount} = $tcount;

    $stats{maskedacount} = $maskedacount;
    $stats{maskedccount} = $maskedccount;
    $stats{maskedgcount} = $maskedgcount;
    $stats{maskedtcount} = $maskedtcount;

    $stats{ncount}       = $ncount;
    $stats{maskedncount} = $maskedncount;
    $stats{othercount}   = $othercount;

    if ($id =~ /(\S+)\.(\S+)/) {
	$stats{orgname} = $1;
	$stats{seqid}   = $2;
    } else {
	$stats{seqid}   = $id;

    }

    return \%stats;
}

sub check_id {
    my ($id) = @_;

    my %res;

    if ($id !~ /(\S+).(\S+)/) {
	$res{result} = 0;
	$res{message} = "Fasta file ids should be of the format orgname.seqname e.g. galGal3.chr1 or emu.scaffold2031. We have[$id]";
	return %res;
    } else {
	$res{result} = 1;
	return %res;
    }
}

sub fix_id {
    my ($id,$org) = @_;

    if ($org) {
	$id = "$org.$id";
    } elsif ($id =~ /(\S+)_(\S+)/) {
	$id = "$1.$2";
    }
    return $id;
}
1;
