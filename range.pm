package range;

use strict;

my $value = qr/[-+]?[\d\.]+/;
my $value_re = qr/$value(?:e$value)?/;

sub check_range {
 my $class = shift;
 my $string = shift;
 my $value = shift;
 my $alert_on_inside = 0;
 my $start_infinity = 0;
 my $end_infinity = 0;
 my $range_start = 0;
 my $range_end = 0;
 my $valid = 0;

 $string =~ s/\s//g;
 unless ( $string =~ /[\d~]/ && $string =~ m/^\@?($value_re|~)?(:($value_re)?)?$/ ) {
  print "invalid range definition '$string'";
  return 1;
 }

 if ($string =~ s/^\@//) {
  $alert_on_inside = 1;
 }

 if ($string =~ s/^~//) { # '~:x'
  $start_infinity = 1;
 }

 if ( $string =~ m/^($value_re)?:/ ) { # '10:'
  $range_start = $1;
  $end_infinity = 1; # overridden below if there's an end specified
  $string =~ s/^($value_re)?://;
  $valid++;
 }

 if ($string =~ /^($value_re)$/) { # 'x:10' or '10'
  $range_end = $string;
  $end_infinity = 0;
  $valid++;
 }

 if ($valid && ($start_infinity == 1 || $end_infinity == 1 || $range_start <= $range_end)) {
  $valid = 1; # useless, so we only need else 
 }
 else {
  print "range not valid";
  return 1;
 }

 my $false = 0;
 my $true = 1;
 if ($alert_on_inside == 1) {
  $false = 1;
  $true = 0;
 }

 if ($end_infinity == 0 && $start_infinity == 0) {
  if ($range_start <= $value && $value <= $range_end) {
   return $false;
  } else {
   return $true;
  }
 } elsif ($start_infinity == 0 && $end_infinity == 1) {
  if ( $value >= $range_start ) {
   return $false;
  } else {
   return $true;
  }
 } elsif ($start_infinity == 1 && $end_infinity == 0) {
  if ($value <= $range_end) {
   return $false;
  } else {
   return $true;
  }
 } else {
  return $false;
 }

 print "can't be here\n";
 return 1;
}

1;
