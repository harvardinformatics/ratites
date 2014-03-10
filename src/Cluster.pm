package Cluster;

use SequenceFeature;

use strict;

use vars qw(@ISA);

@ISA = qw(SequenceFeature);


sub new {
    my $class = shift;

    if (ref $class) {
	$class = ref $class;
    }

    my $self = $class->SUPER::new(@_);
}



sub cluster_hit_features {
    my ($f,$gap) = @_;
    
    my @clus;
    
    my $tmpchr;
    my $tmpstart;
    my $tmpend;
    
    my @f = @$f;
    
  LINE: foreach my $fp (@f) {
      my $found = 0;
      
      foreach my $clus (@clus) {
	  
	  if ($fp->hseqname eq $clus->hseqname &&
	      !(($fp->hstart - $gap) > $clus->hend ||
		($fp->hend + $gap)  < $clus->hstart)) {
	      
              $found = 1;
	      
              if ($fp->start < $clus->start) {
                  $clus->start($fp->start);
              }
              if ($fp->end > $clus->end) {
                $clus->end($fp->end);
              }
	      
              if ($fp->hstart < $clus->hstart) {
                  $clus->hstart($fp->hstart);
              }
              if ($fp->hend > $clus->hend) {
		  $clus->hend($fp->hend);
              }
	      
              push(@{$clus->{features}},$fp);
	      
              next LINE;
	      
	      
	  }
      }
      
      if ($found == 0) {
	  my $newclus = $fp->clone();
	  
	  $newclus->{features} = [];
	  
	  push(@{$newclus->{features}},$fp);
	  
	  push(@clus,$newclus);
      }
  }
    return @clus;
}


sub cluster_features {
    my ($f,$gap) = @_;

    my @clus;

    my $tmpchr;
    my $tmpstart;
    my $tmpend;

#    print "GAP $gap\n";
#    print STDERR "Feat2  $f " . ref($f) . "\n";
    
    my @f = @$f;
    
  LINE: foreach my $fp (@f) {
      my $found = 0;
      
#      print "Looking for " . $fp->seqname . "\t" . $fp->start . "\t" . $fp->end . "\n";

#      if (scalar(@clus) > 0 && $fp->start < $clus[$#clus]->end+$gap) {

    foreach my $clus (@clus) {

#        print "Clus " . $clus->seqname . "\t" . $clus->start . "\t" . $clus->end . "\n";

        my $clusend   = $clus->end + $gap;
        my $clusstart = $clus->start - $gap;

#        print "Start " . ($fp->start - $clusend) . "\n";
#        print "End   " . ($clusstart - $fp->end) . "\n";
        if ($fp->seqname eq $clus->seqname &&

      !($fp->start > $clusend ||
        $fp->end < $clusstart)) {
        
      $found = 1;
  #    print "Clus found\n";
      
      if ($fp->start < $clus->start) {
          $clus->start($fp->start);
      }
      if ($fp->end > $clus->end) {
          $clus->end($fp->end);
      }

      $clus->score($clus->score + $fp->score);
      
      push(@{$clus->{features}},$fp);
      
      next LINE;
      
      
        }
    }
      
#      }
  if ($found == 0) {
  #    print "New clus\n";
      my $newclus = $f->clone();

      $newclus->{features} = [];

      push(@{$newclus->{features}},$fp);
      
      push(@clus,$newclus);
  }
    }
    return @clus;
}

sub cluster_sorted_features {
    my ($f,$gap) = @_;

    my @clus;
    
    my $tmpend = 0;
    my $currclus;
    
    my @f = @$f;
    
  LINE: foreach my $fp (@f) {
      my $found = 0;

      #             -------------------
      #             ------

      #if (defined($currclus) && $fp->strand == $currclus->strand && !(($fp->start - $gap)> $currclus->end ||

      if (defined($currclus) &&  
	  !(($fp->start - $gap)  > $currclus->end ||
            ($fp->end   + $gap)  < $currclus->start)) {

	  push(@{$currclus->{features}},$fp);
    
	  $found = 1;
	  
	  if ($fp->end > $tmpend) {
	      $tmpend = $fp->end;
	      $currclus->end($tmpend);
	  }

	  next LINE;
	  
      }
      
      if ($found == 0) {
	  
	  my $newclus = $fp->clone();
	  $newclus->{features} = [];
	  $newclus->type1("cluster");
	  $newclus->type2("cluster");
	  push(@{$newclus->{features}},$fp);
	  
	  push(@clus,$newclus);

	  $tmpend   = $fp->end;
	  $currclus = $newclus;
      }
  }
  return @clus;
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
