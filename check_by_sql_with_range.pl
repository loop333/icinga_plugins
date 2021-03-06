#!/usr/bin/perl -w

use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use DBI;

# 0 - database
# 1 - username
# 2 - password
# 3 - sql file path
# 4 - description

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

my($ret, $w, $c);
$dbs->bind_columns(undef, \$w, \$c, \$ret);

if (!$dbs->fetch()) {
 print "Fetch error\n";
 exit(3);
}

$dbs->finish;
$dbh->disconnect;

if (range->check_range($c,$ret)) {
 print "CRITICAL: $ret/$w/$c|$ARGV[4]=$ret/$w/$c\n";
 exit(2);
}

if (range->check_range($w,$ret)) {
 print "WARNING: $ret/$w/$c|$ARGV[4]=$ret/$w/$c\n";
 exit(1);
}

print "OK: $ret/$w/$c|$ARGV[4]=$ret/$w/$c\n";
exit(0);
