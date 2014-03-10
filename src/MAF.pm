package MAF;

use vars qw(@ISA);
use strict;
use FileHandle;
use Data::Dumper;
#use Useful;

sub new {
    my ($class) = shift;

    my ($reforg,$dir,$overwrite,$debug) = rearrange(['REFORG','DIR','OVERWRITE','DEBUG'],@_);

    if ($dir !~ /\/$/) {
	$dir .= "/";
    }

    my $self = {
	reforg    => $reforg,
	dir       => $dir,
	overwrite => $overwrite,
	debug     => $debug
    };

    bless $self, $class;

    return $self;

}

sub init {
    my ($self) = @_;

    $self->init_index();
    $self->read_orgfile();
}

sub read_orgfile {
    my ($self) = @_;

    $self->{orgfile} = $self->{dir} . "/orgfile.dat";

    if (! -e $self->{orgfile}) {
	print "ERROR: Can't find orgfile [".$self->{orgfile}."]\n";
	exit;
    }

    my $infile = $self->{orgfile};

    my $fh = new FileHandle();
    $fh->open("<$infile");
    
    my @orgs;
    my %rorgs;

    # This is <ahem> somewhat sensitive to the readme text
    while (<$fh>) {
	my @f = split(' ',$_);
	my $shortname  = $f[0];
	my $commonname = $f[1];
	my $longname   = $f[2];
	
	if ($shortname ne "") {
	    push(@orgs,$shortname);
	    
	    $rorgs{$shortname} = $commonname;
	}
    }
    $fh->close();
    
    my %orgs = map {$_ => 1} @orgs;
 
    $self->{orgs}  = \@orgs;
    $self->{rorgs} = \%rorgs;
}

sub get_rorgs {
    my ($self) = @_;

    return %{$self->{rorgs}};
}
sub get_orgs {
    my ($self) = @_;

    return @{$self->{orgs}};
}

sub sort {
    my ($self) = @_;

    my $overwrite = $self->{overwrite};

    my $indexdir = $self->{dir};
    my $debug    = $self->{debug};

    my $dir   = opendir(DIR,$indexdir);
    my @files = readdir(DIR);

    foreach my $file (@files) {
	my @headers;
	my $foundaln = 0;

	if ($file =~ /\.maf$/) {
	    
	    print STDERR "Sorting maf file $file\n";

	    my $alnfile = $indexdir . $file;

	    my $fh = new FileHandle;
	    $fh->open("<$alnfile");
	    
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
	    $fh->open(">$alnfile.new");
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
	    system("mv $alnfile $alnfile.orig");
	    system("mv $alnfile.new $alnfile");

	}
    }
}
sub init_index {
    my ($self) = @_;

    my $overwrite = $self->{overwrite};

    my @pieces;

    if (!$self->{has_index}) {
	my $indexdir = $self->{dir};
	my %orgs;
	
	my $dir   = opendir(DIR,$indexdir);
	my @files = readdir(DIR);

	my $orgfile = "$indexdir/orgfile.dat";

	foreach my $file (@files) {
	    if ($file =~ /\.maf$/) {
		my $index   = $indexdir . "$file.index";
		my $alnfile = $indexdir . $file;

		if (! -e $index || ! -s $orgfile || $overwrite) {
		    print STDERR "Indexing alignment file $file to $index\n";

		    my $fh = new FileHandle;
		    $fh->open("<$alnfile");
		    
		    open(OUT,">$index");

		    my $line;
		    my $pos = tell($fh);
		    my $prev;

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
		    
		    close(IN);
		    close(OUT);
		}
	    }
	}

	$self->write_orgfile(\%orgs);

	$self->{has_index} = 1;
    }
    return;
}

sub write_orgfile {
    my ($self,$orgs) = @_;

    my $dir = $self->{dir};
    my $filename = "$dir/orgfile.dat";

    if (-s $filename == 0 || $self->{overwrite}) {
	my $fh = new FileHandle();
	$fh->open(">$filename");
	
	foreach my $org (keys %$orgs) {
	    print $fh "$org\t$org\t$org\n";
	}
	$fh->close();
    }
}

sub get_maf_filehandle {
    my ($self,$chr,$start,$end) = @_;

    my $indexdir = $self->{dir};
    my $aln      = $indexdir . "$chr.maf";
    my $index    = $indexdir . "$chr.maf.index";

    my $reforg   = $self->{reforg};

    my %index;

    if (! -e $aln) {
	print "ERROR No aln file $aln\n";
	exit(0);
    }
    if (! -e $index) {
	print "No index file $index\n";
	exit(0);
    }

    open(IN,"<$index");
    
    sysseek(\*IN, 0, 2);                     # Find filesize
    my $filesize = systell(\*IN);

    my %oldcoords;

    my ($fh,$alnpos,$startcoord,$endcoord)= $self->findpos(\*IN,0,$filesize,$start,\%oldcoords,0,$filesize);

    my $fh2 = new FileHandle();

    $fh2->open("<$indexdir/$chr.maf");

    sysseek($fh2,$alnpos,0);

    $fh->close();

    return $fh2;
}

sub get_align {
    my ($self,$chr,$start,$end) = @_;

    my $debug = $self->{debug};

    my $fh = $self->get_maf_filehandle($chr,$start,$end);

    my %piece;
    my %fullstr;

    my $prevend = $start-1;
    my $reforg  = $self->{reforg};

    my %orgs = map {$_ => 1} $self->get_orgs();

    while (%piece = $self->read_piece($fh)) {
	foreach my $org (keys %piece) {
	    if ($org ne "lines") {
		$orgs{$org} = 1;
	    }
	}
	
	my $piece_start = $piece{$reforg}{start};
	my $piece_end   = $piece{$reforg}{end};

	print STDERR "\n==============================\n" if $debug;
	
	if ($piece{$reforg}{start} > $end) {
	    print STDERR "Found end " . $piece{$reforg}{start} . " $end\n" if $debug;
	    $self->{fullstr} = \%fullstr;
	    return \%fullstr;
	}
	my $jointype = $self->get_jointype(\%piece,$prevend);

	print STDERR "Join type $jointype\n" if $debug;

	if ($jointype eq "PAD") {
	    $self->pad_fullstrings(\%piece,$prevend,\%fullstr);
	} elsif ($jointype eq "TRIM") {
	    $self->trim_piecestart(\%piece,$prevend);
	} elsif ($jointype eq "SKIP") {
	} else {
	    print STDERR "ERROR: Shouldn't get here. Unknown join type $jointype for $chr $piece_start $piece_end\n";
	}

	if ($jointype ne "SKIP") {
	    $self->add_piece(\%fullstr,\%piece);

	    if ($debug) {
		print STDERR "\n";
		my $tmpstr =  substr($piece{$reforg}{string},0,100);
		
		print STDERR sprintf("%10s %10d %10d %s\n",$reforg,$piece_start,$piece_end,$tmpstr);
		foreach my $org ($self->get_orgs()) {
		    if ($org ne $reforg) {
			
			my $tmpstr = substr($piece{$org}{string},0,100);
			if ($tmpstr =~ /[ACGT]/) {
			print STDERR sprintf("%10s %10s %10s %s\n",$org,"","",$tmpstr);
		    }
		    }
		}
		print STDERR "\n";
	    }
	    $prevend = $piece{$reforg}{end};
	}

    }

    $self->{fullstr} = \%fullstr;
    return $self->{fullstr};
}

sub add_piece {
    my ($self,$fullstr,$piece) = @_;

    my $reforg = $self->{reforg};
    my @orgs   = $self->get_orgs();

    print "PRG " . join(', ',@orgs) . "\n";
    foreach my $org (@orgs) {
	if (!defined($piece->{$org}{string})) {
	    $piece->{$org}{string} = '-' x length($piece->{$reforg}{string});
	}
	$fullstr->{$org} .= $piece->{$org}{string};
	#print "Lenght $org\t".length($fullstr->{$org}) . "\n";
    }
}

sub trim_piecestart {
    my ($self,$piece,$prevend) = @_;


    #   xxxxxxxxxx
    #        xxxxxxxxxxxxxxxxxxxxxxxxx
    #            ^
    #            prevend
    #        ^piecestart
    #             ^ new piecestart

    my $reforg      = $self->{reforg};
    my $piece_start = $piece->{$reforg}{start};
    my $piece_end   = $piece->{$reforg}{end};

    my @c = split(//,$piece->{$reforg}{string});

    # We need to find the position in the string to trim to
    # We also need to check that the coords are right

    my $i      = 1;
    my $coord  = $piece_start-1;
    my $strstart;

    while ($i < scalar(@c)) {

	# Advance the coords if we have a non-gap characgter
	if ($c[$i] ne '-') {
	    $coord++;
	}

	if ($coord == $prevend) {
	    $strstart = $i;
	    last;
	}

	$i++;
    }
    
    if ($self->{debug}) {
	print STDERR "\n";
	print STDERR "Original string " . substr($piece->{$reforg}{string},0,100) . "\n";
	print STDERR "Trimming - $strstart\n";
    }

    my @orgs = $self->get_orgs();

    foreach my $org (@orgs) {
	my $tmpstr1 = $piece->{$org}{string};
	my $tmpstr2 = $tmpstr1;
	
	$tmpstr1 = substr($tmpstr1,$i);
	$tmpstr2 = substr($tmpstr2,0,$i);
	
	$tmpstr2 =~ s/-//g;
	
	my $offset = length($tmpstr2);
	
	$piece->{$org}{start} = $prevend+1;
	$piece->{$org}{len}   = $piece_end - $prevend - 1;
	
	$piece->{$org}{string} = $tmpstr1;
	
    }
    if ($self->{debug}) {
	print STDERR "New string" . substr($piece->{$reforg}{string},0,100) . "\n";
    }

    return $piece;
}

sub pad_fullstrings {
    my ($self,$piece,$prevend,$fullstr) = @_;

    my $reforg      = $self->{reforg};
    my $piece_start = $piece->{$reforg}{start};

    my $padsize  = $piece_start - $prevend - 1;
    my $padstr1  = 'N' x $padsize;
    my $padstr2  = '-' x $padsize;

    my @orgs    = $self->get_orgs();

    foreach my $org (@orgs) {
	if ($org eq $reforg) {
	    $fullstr->{$org} .= $padstr1;
	} else {
	    $fullstr->{$org} .= $padstr2;
	}
    }

}

sub get_jointype {
    my ($self,$piece,$prevend) = @_;
    
    my $reforg      = $self->{reforg};
    my $piece_start = $piece->{$reforg}{start};
    my $piece_end   = $piece->{$reforg}{end};
    my $jointype;


    if ($piece_end <= $prevend) {

	#    -------------------             previous piece
	#             --                     current piece

	$jointype = "SKIP";

    } elsif ($prevend < $piece_start) {

	#    -------------------             previous piece
	#                          ------    current piece
	
	$jointype = "PAD";

    } elsif ($piece_start <= $prevend) {

	$jointype = "TRIM";

	#    -------------------             previous piece
	#                    ------------    current piece

    }

    return $jointype;
}

sub sort_orgs_by_pid {
    my ($self) = @_;

    my $reforg  = $self->{reforg};
    my $fullstr = $self->{fullstr};
    my @orgs    = $self->get_orgs();

    my %pid;

    my $i       = 0;
    my $fulllen = length($fullstr->{$reforg});
    my $chunk   = int(($fulllen-100)/10);

    print "Full length $fulllen $chunk\n";
    foreach my $org (@orgs) {
	my $pos   = 0;
	my $count = 0;

	# Find pieces with up to 50 gaps in
	while ($fullstr->{$org}  =~ /-{50}-+/g && $count < 50) {
	    my $start   = $-[0];
	    my $end     = $+[0];


	    if ($pos) {
		my $refseq  = substr($fullstr->{$reforg},$pos,$start-$pos);
		my $orgseq  = substr($fullstr->{$org},$pos,$start-$pos);

		$refseq =~ tr/atgc/ATGC/;
		$orgseq =~ tr/atgc/ATGC/;

		#print  $org . "\t" . $-[0] . " " .$+[0] . " " .$refseq ."\n";
		#print  $org . "\t" . $-[0] . " " .$+[0] . " " .$orgseq ."\n";
		my $pid = int($self->get_pid($refseq,$orgseq));
		
		if ($pid{$org}) {
		    $pid{$org} = int(($pid{$org} + $pid)/2);
		} else {
		    $pid{$org} = $pid;
		}
		$count++;
		#print "PID $org ".$pid{$org}. " $count\n";
	    }
	    $pos = $end;
	}
    }

    my @neworgs = sort {$pid{$b} <=> $pid{$a}} @orgs;

    my %neworgs = map {$_ => 1} @neworgs;

    $self->{orgs} = \@neworgs;

    return $self->get_orgs();
}
sub sort_orgs_by_coverage {
    my ($self) = @_;

    my $reforg  = $self->{reforg};
    my $fullstr = $self->{fullstr};
    my @orgs    = $self->get_orgs();

    my %cov;

    my $fulllen = length($fullstr->{$reforg});

    foreach my $org (@orgs) {
	my $tmpseq = $fullstr->{$org};
	my $count = ($tmpseq =~ tr/ATGC//);
	$cov{$org} = $count;
	print "ORG $org $count $fulllen\n";
    }

    my @neworgs = sort {$cov{$b} <=> $cov{$a}} @orgs;
    $self->{orgs} = \@neworgs;

    return $self->get_orgs();
}


sub get_pid {
    my ($self,$str1,$str2) = @_;

    my @c1 = split(//,$str1);
    my @c2 = split(//,$str2);

    my $match = 0;
    my $num   = 0;

    my $i = 0;

    while ($i < scalar(@c1)) {
	my $c1 = $c1[$i];
	my $c2 = $c2[$i];
	
	if ($c1 ne '-' && $c2 ne '-') {
	    $num++;

	    if ($c1 eq $c2) {
		$match++;
	    }
	}
	$i++;
    }

    if ($num > 0) {
	return int(100*$match/$num);
    } else {
	return 0;
    }
}


sub orgdir {
    my ($self,$orgdir) = @_;

    $self->{orgdir} = $orgdir;
}

sub get_region {
    my ($self,$chr,$start,$end) = @_;

    my $nib = $self->{orgdir} . "/$chr.fa.nib";
    
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

sub get_ref_seq {
    my ($self,$chr,$start,$end) = @_;

    $start--;

    # This isn't going to work
    my $cmd = "nibFrag -masked -name=$chr.$start-$end /ahg/scr3/mammals/local_data/hg18_seq/$chr.nib $start $end + stdout |";
    #print STDERR "Command $cmd\n";

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


sub findpos { 
    my ($self,$fh,$startpos,$endpos,$coord,$oldcoords,$hops,$filesize) = @_;

    print STDERR "\n\nFinding index file position for coord $coord  between $startpos - $endpos\n";

    if (abs($startpos - $endpos) <= 1) {
	return $fh,$startpos,$coord,$coord;
    }

    my $halfpos   = int(($endpos+$startpos)/2);

    print STDERR "Checking mid position $halfpos\n";

    my ($alnpos,$halfstart,$halfend) = $self->find_coord($fh,$halfpos,$filesize);

    print STDERR "Coordinates at the halfway position are $halfstart - $halfend   : $coord\n";

    # If the old coord is the same as the new coord we are starting in a gap

    if ($oldcoords->{$halfstart} == 1) {
	if ($halfstart < $coord) {
	    return $fh,$alnpos,$halfstart,$halfend;
	} else {
	    $fh  = $self->backup_line($fh);
	    my ($alnpos,$halfstart,$halfend) = $self->find_coord($fh,$halfpos,$filesize);
	    return $fh,$alnpos,$halfstart,$halfend;
	}
    }
    $oldcoords->{$halfstart} = 1;

    if ($coord >= $halfstart && $coord <= $halfend) {
	return $fh,$alnpos,$halfstart,$halfend;
    } elsif ($halfstart > $coord) {

	#print "Recursing in lower half\n";

	if ($hops < 100) {
	    $hops++;
	    $self->findpos($fh,$startpos,$halfpos,$coord,$oldcoords,$hops,$filesize);
	} else {
	    return;
	}
	
    } elsif ($halfend < $coord) {

#	print "Recursing in upper half\n";

	if ($hops < 100) {
	    $hops++;

	    $self->findpos($fh,$halfpos,$endpos,$coord,$oldcoords,$hops,$filesize);
	} else {
	    return;
	}
    }
}


sub find_coord {
    my ($self,$fh,$halfpos,$filesize) = @_;

    sysseek($fh,$halfpos,0);

    $fh = $self->backup_line($fh);

    my $startcoord;
    my $endcoord;
    my $alnpos;

    my $pos = systell($fh);

    my $prepos = $pos;

    my $c;

    sysread($fh,$c,1);

    while ($c ne "\t") {
	#print "got $pos :$c:\n";
	$startcoord .= $c;
	$pos++;
	if ($pos >= $filesize) {
	   return;
	}
	sysseek($fh,$pos,0);
	sysread($fh,$c,1);
    }

    $pos++;

    sysread($fh,$c,1);
    
    while ($c ne "\t") {
	#print "got coord :$c:\n";
	$endcoord .= $c;
	$pos++;
	if ($pos >= $filesize) {
	   return;
	}
	sysseek($fh,$pos,0);
	sysread($fh,$c,1);
    }

    $endcoord = $endcoord + $startcoord-1;
    $pos++;

    sysread($fh,$c,1);
    
    while ($c ne "\n") {
	#print "got coord :$c:\n";
	$alnpos .= $c;
	$pos++;
	if ($pos >= $filesize) {
	   return;
	}
	sysseek($fh,$pos,0);
	sysread($fh,$c,1);
    }

    sysseek($fh,$prepos,0);

    return ($alnpos,$startcoord,$endcoord);
}

	

sub systell {
    my ($self) = @_;
    use Fcntl 'SEEK_CUR';
    sysseek($_[0], 0, SEEK_CUR);
}

sub backup_line {
    my ($self,$fh) = @_;

    my $pos = systell($fh);

    my $c;

    sysread($fh,$c,1);
    
    #print "Pos $pos :$c:\n";
    while ($c ne "\n" && $pos >= 0) {
	$pos--;
	#print "Pos $pos :$c:\n";
	sysseek($fh,$pos,0);
	sysread($fh,$c,1);
    }

    $pos++;

    sysseek($fh,$pos,0);

    #print "Got beginning of line\n";

    return $fh;
}

sub strip_gapsC {
    my ($self,$seq1,$seq2) = @_;

    strip_gappedC($seq1,$seq2);

    return ($seq1,$seq2);
}

sub strip_gaps {
  my ($self,$seq1,$seq2) = @_;

  my @c1 = split(//,$seq1);
  my @c2 = split(//,$seq2);

  my $i = 0;

  my $newseq2;
  my $count = scalar(@c1);

  while ($i < $count) {

    if ($c1[$i] ne '-') {
       $newseq2 .= $c2[$i];
    }
    $i++;
 }
 return $newseq2;
}

sub piece_to_maf {
    my ($self,$piece) = @_;

    my @lines=  @{$piece->{lines}};

    my $str = "";

    foreach my $line (@lines) {
	if ($line =~ /a score/) {
	    $str = $line;
	}
    }

    my $reforg = $self->{reforg};

    my $chr    = $piece->{$reforg}{chr};
    my $start  = $piece->{$reforg}{start};
    my $end    = $piece->{$reforg}{end};
    my $len    = $piece->{$reforg}{len};
    my $strand = $piece->{$reforg}{strand};
    my $string = $piece->{$reforg}{string};
    my $chrlen = $piece->{$reforg}{chrlen};

    $str .= sprintf("s %20s     %10d %5d %1s %10d %s\n","$reforg.$chr",$start,$len, $strand ,$chrlen, $string);

    my @orgs = $self->get_orgs;

    foreach my $org ($self->get_orgs) {

	if ($org ne $reforg) {
	    my $chr    = $piece->{$org}{chr};
	    my $start  = $piece->{$org}{start};
	    my $end    = $piece->{$org}{end};
	    my $len    = $piece->{$org}{len};
	    my $strand = $piece->{$org}{strand};
	    my $string = $piece->{$org}{string};
	    my $chrlen = $piece->{$org}{chrlen};
	    $str .= sprintf("s %20s     %10d %5d %1s %10d %s\n","$org.$chr",$start,$len, $strand ,$chrlen, $string);
	}
    }
    $str .= "\n";
    return $str;
}

	
sub read_piece {
    my ($self,$fh) = @_;

    #String s hg18.chr1    10999750 392 + 247249719 taggttctggcgtcaaactcctgggcccatactgtcctcctgcctcgaccccaatgtgctgagccaccatgcc-cagccACAATCTTGTTACCtttctttt

    my $prevline;
    my $line;
    my %piece;

    my $foundstart = 0;

    while (($line = <$fh>) && $line ne "\n") {
	#print "Piece $line\n";
	
	if ($line =~ /^s/) {
	    $foundstart = 1;
	 #   print $line;
	    my ($dum,$tmporg,$coord,$len,$strand,$chrlen,$string) = split(' ',$line);
	    
	    my $org;
	    my $chr;
	    
	    if ($tmporg =~ /(\S+)\.(\S+)/) {
		$org = $1;
		$chr = $2;
	    }
	    if ($dum eq "s") {
		$piece{$org}{chr}    = $chr;
		$piece{$org}{start}  = $coord+1;
		$piece{$org}{len}    = $len;
		$piece{$org}{end}    = $coord + $len;
		$piece{$org}{strand} = $strand;
		$piece{$org}{chrlen} = $chrlen;
		$piece{$org}{string} = $string;
	    }
	}
	$prevline = $line;
	push(@{$piece{lines}},$line);
    }
    return %piece;
}


sub trim_piece {
    my ($self,$piece,$start,$end,$reforg,$piece_coord) = @_;

    # First find the string offsets in the human sequence (which will be gapped)

    #print "Trim start end $start $end\n";

    my $strstart;
    my $strend;

    my @c = split(//,$piece->{$reforg}{string});

    my $i      = 0;
    my $coord  = 0;

    my $piece_start = $piece_coord;
    my $piece_end;

    while ($i < scalar(@c)) {
	#print "Coord $coord  " . scalar(@c) . " $i\n";

	if ($coord == $start) {
	    $strstart = $i;
	    #$piece_start = $piece_coord;
	    $piece_start = $coord + $piece_start;

	}
	if ($coord-$piece->{$reforg}{len} == $end) {
	    $strend    = $i;
	    #$piece_end = $piece_coord;
	    $piece_end = $coord + $piece_start;
	}

	if ($c[$i] ne '-') {
	    $coord++;
	    $piece_coord++;
	}
	$i++;
    }

    $piece_end = $piece_coord-1 unless $piece_end;
    $strend    = $i-1 unless $strend;

    #my %newstr;

    #print "Trimming a string "  . (length($piece->{hg18}{string})) . " long to $strstart $strend\n";
    #print "Trimming a string "  . (length($piece->{hg18}{string})) . " long to $piece_start $piece_end\n";

    #print "String length " . length($piece->{$reforg}{string}) . "\n";
    my $len;

    foreach my $org (keys %$piece) {
	if ($org ne "lines") {
	    my $tmpstr = $piece->{$org}{string};
	    #print "Start $strstart $tmpstr\n";
	    $tmpstr = substr($tmpstr,$strstart,$strend-$strstart+1);
	    $piece->{$org}{start} = $piece_start;
	    $piece->{$org}{end}   = $piece_end;
	    $piece->{$org}{len}   = $piece_end-$piece_start;

	    $piece->{$org}{string} = $tmpstr;
	    #print "Piece " . $tmpstr . "\n";
	    undef($tmpstr);
	}

    }
    return $piece;
}
sub print_piece {
    my ($self,$piece) = @_;

    my %piece = %$piece;
    my @orgs = $self->get_orgs();

    foreach my $org (@orgs) {

	if (defined($piece{$org})) {
	    printf("%12s\t%12d\t%12d\t%s\t%s\n", $org, $piece{$org}{start}, $piece{$org}{end}, substr($piece{$org}{string},0,40), substr($piece{$org}{string},-40,40));
	    #print "Len $org " . $piece{$org}{len}."\n";
	}
    }
}

sub copy_piece {
    my ($self,$p) = @_;

    my %p = %$p;
    my %newp;

    foreach my $key (keys %p) {

	if ($key ne "lines") {
	    my %f = %{$p{$key}};
	
	    foreach my $key2 (keys %f) {
		$newp{$key}{$key2} = $f{$key2};
	    }
	} else {

	    push(@{$newp{lines}},@{$p{lines}});
	}
    }

    return %newp;
}
	    

sub strip_str {
    my ($self,$fullstr) = @_;

    my %fullstr = %$fullstr;

    my $hstr = $fullstr{$self->{reforg}};
    my @hc   = split(//,$hstr);

    my %newstr;
    my @orgs = $self->get_orgs();


    foreach my $org (@orgs) {
	if ($org ne $self->{reforg}) {

	    my $tstr = $fullstr{$org};

	    my @tc   = split(//,$tstr);

	    my $i = 0;

	    my $newhstr;
	    my $newtstr;

	    while ($i < scalar(@hc)) {

		if ($hc[$i] ne '-' ) {
		    $newhstr .= $hc[$i];
		    $newtstr .= $tc[$i];
		}

		$i++;
	    }

	    $newstr{$org}{h} = $newhstr;
	    $newstr{$org}{t} = $newtstr;

	    undef($tstr);
	    undef(@tc);
	}
    }
    undef(%fullstr);
    return %newstr;
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


$ENV{'PERL_INLINE_DIRECTORY'}='/tmp';

use Inline C => << 'END_OF_C_CODE';

int strip_gappedC(SV* seq1, SV* seq2) {

   int i=0;
   int z=0;

   int seqlen1 = 0;
   int seqlen2 = 0;

   char *seqbuf1;
   char *seqbuf2;


  // ok set up and copy data from input to stuff we are going to munge on
  // we don\'t want to modify the perl data inplace in here, that would be bad

   seqlen1 = strlen(SvPV(seq1,PL_na)) + 1;
   seqlen2 = strlen(SvPV(seq2,PL_na)) + 1;


   seqbuf1 = malloc(sizeof(char)*seqlen1);
   seqbuf2 = malloc(sizeof(char)*seqlen2);


   strcpy(seqbuf1,SvPV(seq1, PL_na));
   strcpy(seqbuf2,SvPV(seq2, PL_na));


   // setup some space for the new buffer to return.
   // this will be the same size or smaller than the input string

   char *newseq1;
   char *newseq2;

   newseq1 = malloc(sizeof(char)*seqlen1);
   newseq2 = malloc(sizeof(char)*seqlen2);

//   fprintf(stderr, "Length of seq1 SV  = %d\n",strlen(SvPV(seq1, PL_na)));
 //  fprintf(stderr, "Length of seq2 SV  = %d\n",strlen(SvPV(seq2,PL_na)));
  // fprintf(stderr, "Length of seq1 (buffer) = %d\n",strlen(seqbuf1));
   //fprintf(stderr, "Length of seq2 (buffer) = %d\n",strlen(seqbuf2));


  // fprintf (stderr, "Inside C we have:\nseq1=%s\nseq2=%s\n",seqbuf1, seqbuf2);

   while (i < seqlen1) {
       if (seqbuf1[i] != '-') {
	   newseq1[z] = seqbuf1[i];
	   newseq2[z] = seqbuf2[i];
	   z++;
       }
       i++;
   }

   // this bit does the data copy for the return values

       sv_setpvn(seq1, newseq1, z);
   sv_setpvn(seq2, newseq2, z);

   free(seqbuf1);
   free(seqbuf2);

   free(newseq1);
   free(newseq2);

   return 1;
}

END_OF_C_CODE

1;
