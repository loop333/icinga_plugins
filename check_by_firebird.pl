#!/usr/bin/perl -w

use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use DBI;

# 0 host
# 1 db
# 2 user
# 3 password
# 4 file
# 5 label
# 6 warning
# 7 critical

$ENV{'FIREBIRD'} = '/monitor/icinga/lib';

open(INFILE,"<$ARGV[4]");
my @sql = <INFILE>;
close(INFILE);

my $dbh = DBI->connect("dbi:Firebird:host=" . $ARGV[0] . ";db=" . $ARGV[1],$ARGV[2],$ARGV[3],{PrintError=>0});
if (!$dbh) {
 print "Can't connect to database: " . DBI->errstr . "\n";
 exit(3);
}

my ($d,$m,$y) = (localtime)[3,4,5];
$y = $y + 1900;
$m = $m + 1;

my $sqlstr = join('',@sql);

$sqlstr =~ s/\{DD\}/sprintf("%02d",$d)/ge;
$sqlstr =~ s/\{MM\}/sprintf("%02d",$m)/ge;
$sqlstr =~ s/\{YYYY\}/sprintf("%04d",$y)/ge;

my $dbs = $dbh->prepare($sqlstr);
if (!$dbs) {
 print "Can't prepare statement: " . $dbh->errstr . "\n";
 exit(3);
}

my $dbe = $dbs->execute();
if (!$dbe) {
 print "Can't execute statement: " . $dbh->errstr . "\n";
 exit(3);
}

my($ret);
$dbs->bind_columns(undef, \$ret);

if (!$dbs->fetch()) {
 print "Fetch error\n";
 exit(3);
}

$dbs->finish;
$dbh->disconnect;

if (range->check_range($ARGV[7],$ret)) {
 print "CRITICAL: $ARGV[5]=$ret/$ARGV[6]/$ARGV[7]|$ARGV[5]=$ret/$ARGV[6]/$ARGV[7]\n";
 exit(2);
}

if (range->check_range($ARGV[6],$ret)) {
 print "WARNING: $ARGV[5]=$ret/$ARGV[6]/$ARGV[7]|$ARGV[5]=$ret/$ARGV[6]/$ARGV[7]\n";
 exit(1);
}

print "OK: $ARGV[5]=$ret/$ARGV[6]/$ARGV[7]|$ARGV[5]=$ret/$ARGV[6]/$ARGV[7]\n";
exit(0);
