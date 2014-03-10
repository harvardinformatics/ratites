use strict;

$| = 1;


my $id;
my $seq;

while (<>) {
    chomp;
    my $line = $_;
    if ($line =~ /^>/) {
	print $line . "\n";
    } else {
	$line =~ s/[^AGTC\n\r]/N/g;
	print $line . "\n";
    }
}
	
