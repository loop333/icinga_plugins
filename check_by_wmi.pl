#!/usr/bin/perl -w

use strict;
use lib "/monitor/icinga/libexec";
use range;

# $ARGV[0] - host
# $ARGV[1] - login
# $ARGV[2] - password
# $ARGV[3] - sql file
# $ARGV[4] - name
# $ARGV[5] - warning
# $ARGV[6] - error
# $ARGV[7] - parameter

sub output_and_error_of {
 local *CMD;
 local $/ = undef;
 my $pid = open CMD, "-|";
 if (defined($pid)) {
  if ($pid) {
   return <CMD>;
  } else {
   open STDERR, ">&STDOUT" and exec @_;
   exit(1);
  }
 }
 return undef;
}

my $res;
my @lines;
my $last;
my $ret;
my $sqlstr;

if (!defined($ARGV[7])) {
 $ARGV[7] = "?";
}

open(INFILE,"<$ARGV[3]");
my @sql = <INFILE>;
close(INFILE);

$sqlstr = join('',@sql);
$sqlstr =~ s/\?/$ARGV[7]/g;

#print "/monitor/icinga/libexec/wmic -U $ARGV[1]%$ARGV[2] //$ARGV[0] \"$sqlstr\"\n";

$res = output_and_error_of("/monitor/icinga/libexec/wmic -U $ARGV[1]%$ARGV[2] //$ARGV[0] \"$sqlstr\"");
if (length($res) == 0) {
 print "UNKNOWN: $ARGV[4]=null/$ARGV[5]/$ARGV[6]|$ARGV[4]=null/$ARGV[5]/$ARGV[6]\n";
 exit(3);
}
if (index($res, 'ERROR:') != -1) {
 print "UNKNOWN: $ARGV[4]=null/$ARGV[5]/$ARGV[6]|$ARGV[4]=null/$ARGV[5]/$ARGV[6]\n";
 exit(3);
}
#print "res: <$res>\n";
@lines = split /\n/, $res;
$last = $lines[$#lines];
#print "last: $last\n";
$last =~ m/(\d+)$/;
$ret = $1;
#print "ret: $ret\n";

if (range->check_range($ARGV[6],$ret)) {
 print "CRITICAL: $ARGV[4]=$ret/$ARGV[5]/$ARGV[6]|$ARGV[4]=$ret/$ARGV[5]/$ARGV[6]\n";
 exit(2);
}

if (range->check_range($ARGV[5],$ret)) {
 print "WARNING: $ARGV[4]=$ret/$ARGV[5]/$ARGV[6]|$ARGV[4]=$ret/$ARGV[5]/$ARGV[6]\n";
 exit(1);
}

print "OK: $ARGV[4]=$ret/$ARGV[5]/$ARGV[6]|$ARGV[4]=$ret/$ARGV[5]/$ARGV[6]\n";
exit(0);
