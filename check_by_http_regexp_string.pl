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
use Time::HiRes qw(gettimeofday);

use range;

my $start;
my $time;
my $ret;

my $lwp = LWP::UserAgent->new(timeout => 30);
my $request = HTTP::Request->new(GET => $ARGV[0]);
$start = gettimeofday;
my $response = $lwp->request($request);
$time = gettimeofday-$start;
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

if (range->check_range($ARGV[5],$time)) {
 print "CRITICAL: $ARGV[3]=$ret/$ARGV[4]/$ARGV[5]|$ARGV[3]=$ret/$ARGV[4]/$ARGV[5]\n";
 exit(2);
}

if (range->check_range($ARGV[4],$time)) {
 print "WARNING: $ARGV[3]=$ret/$ARGV[4]/$ARGV[5]|$ARGV[3]=$ret/$ARGV[4]/$ARGV[5]\n";
 exit(1);
}

$time=sprintf("%.3f",$time);

print "OK: $ARGV[3]=$time/$ARGV[4]/$ARGV[5]|$ret\n";
#print $end-$start;
#print "\n";
exit(0);
