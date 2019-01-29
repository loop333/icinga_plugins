#!/usr/bin/perl -w

# icinga: -epn

# 0 url
# 1 match string
# 2 replace string
# 3 label
# 4 warning
# 5 critical

use strict;

use lib "/monitor/icinga/libexec";

use LWP::UserAgent;
use HTTP::Request;
#use Time::HiRes qw(gettimeofday);

use range;

#my $start;
#my $end;
my $ret;

my $lwp = LWP::UserAgent->new(timeout => 30);
my $request = HTTP::Request->new(GET => $ARGV[0]);
#$start = gettimeofday;
my $response = $lwp->request($request);
#$end = gettimeofday;
if ($response->is_success)
{
 $ret = $response->content;
 if ($ret =~ /$ARGV[1]/)
  {
   $ret =~ s/.*$ARGV[1].*/$ARGV[2]/seeg;
  }
 else
  {
   print "UNKNOWN: String <" . $ARGV[1] . "> not found\n";
   exit(3);
  }
}
else
{
 print "UNKNOWN: " . $response->status_line . "\n";
 exit(3);
}

if (range->check_range($ARGV[5],$ret)) {
 print "CRITICAL: $ARGV[3]=$ret/$ARGV[4]/$ARGV[5]|$ARGV[3]=$ret/$ARGV[4]/$ARGV[5]\n";
 exit(2);
}

if (range->check_range($ARGV[4],$ret)) {
 print "WARNING: $ARGV[3]=$ret/$ARGV[4]/$ARGV[5]|$ARGV[3]=$ret/$ARGV[4]/$ARGV[5]\n";
 exit(1);
}

print "OK: $ARGV[3]=$ret/$ARGV[4]/$ARGV[5]|$ARGV[3]=$ret/$ARGV[4]/$ARGV[5]\n";
#print $end-$start;
#print "\n";
exit(0);
