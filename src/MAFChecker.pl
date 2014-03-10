package MAFChecker;

use strict;
use FileHandle;

sub new {
    my ($class) = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}


sub get_ids {
    my ($file) = @_;

    my $fh = new FileHandle();

    $fh->open("<$file");

    my %ids;

    while (my $line = <$fh>) {
	chomp;

	if ($line =~ /^s +(\S+)/) {
	    $ids{$1} = 1;
	}
    }

    $fh->close();
    return keys %ids;
}

sub check_ids {
    my ($file) = @_;

    my @ids= MAFChecker::get_ids($file);
    my %res;

    foreach my $id (@ids) {

	if ($id !~ /(\S+)\.(\S+)/) {
	    $res{$id}{result} = 0;
	    $res{$id}{message} = "ERROR: ID [$id] not of format orgname.seqname e.g. galGal3.chr5 or emu.scaffold6";
	}
    }
    return \%res;
}

sub fix_ids {
    my ($file) = @_;

    my $infh = new FileHandle();
    my $outfh = new FileHandle();

    my $res = system("mv $file $file.orig");

    if ($res) {
	print "ERROR: Couldn't move maf file [$file] to [$file.orig].  Can't fix ids\n";
	return;
    }

    $infh->open("<$file.orig");
    $outfh->open(">$file");
    
    my %ids;

    while (my $line = <$infh>) {
	chomp;

	if ($line =~ /^(s +\S+)_(\S+)/) {
	    $line =~ s/^(s +\S+)_(\S+)/$1\.$2/;
	}
	print $line . "\n";
    }

    $fh->close();
    
}  

1;
