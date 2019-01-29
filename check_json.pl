#!/usr/bin/perl -w

# 0 url
# 1 attribute
# 2 label
# 3 warning
# 4 critical

use warnings;
use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use LWP::UserAgent;
use JSON 'decode_json';
use Data::Dumper;

my $ua = LWP::UserAgent->new;

$ua->agent('check_json/0.1');
$ua->default_header('Accept' => 'application/json');
$ua->protocols_allowed( [ 'http', 'https'] );
$ua->parse_head(0);
$ua->timeout(15);

my $response = ($ua->get($ARGV[0]));

if ($response->is_success) {
 if (!($response->header("content-type") =~ 'application/json')) {
  print "Content type is not JSON: ".$response->header("content-type")."\n";
  exit(3);
  }
} else {
 print "Connection failed: ".$response->status_line."\n";
 exit(2);
}

my $json_response = decode_json($response->content);
#print Dumper($json_response)."\n";

my $value;
my $exec = '$value = $json_response->'.$ARGV[1];
eval $exec;

if (!defined $value) {
 print "No value received\n";
 exit(3);
}
#print "Value=".$value."\n";

if (range->check_range($ARGV[4],$value)) {
 print "CRITICAL: $ARGV[2]=$value/$ARGV[3]/$ARGV[4]|$ARGV[2]=$value/$ARGV[3]/$ARGV[4]\n";
 exit(2);
}

if (range->check_range($ARGV[3],$value)) {
 print "WARNING: $ARGV[2]=$value/$ARGV[3]/$ARGV[4]|$ARGV[2]=$value/$ARGV[3]/$ARGV[4]\n";
 exit(1);
}

print "OK: $ARGV[2]=$value/$ARGV[3]/$ARGV[4]|$ARGV[2]=$value/$ARGV[3]/$ARGV[4]\n";
exit(0);
