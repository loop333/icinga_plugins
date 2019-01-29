#!/usr/bin/perl -w

use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use DBI;

# 0 tns
# 1 username
# 2 password
# 3 sql file
# 4 label
# 5 warning
# 6 critical

open(INFILE,"<$ARGV[3]");
my @sql = <INFILE>;
close(INFILE);

my $dbh = DBI->connect("DBI:Oracle:" . $ARGV[0],$ARGV[1],$ARGV[2],{PrintError=>0});
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
 print "Fetch error: " . $dbh->errstr . "\n";
 exit(3);
}

$dbs->finish;
$dbh->disconnect;

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
