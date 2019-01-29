#!/usr/bin/perl -w

# host
# service
# warning 1 
# critical 1
# warning 2 
# critical 2
# value 1
# value 2
# info

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use DBI;

open(INFILE,"<$ARGV[3]");
my @sql = <INFILE>;
close(INFILE);

my $cmd_file = "/monitor/icinga/var/rw/icinga.cmd";

my $dbh = DBI->connect("DBI:Oracle:" . $ARGV[0],$ARGV[1],$ARGV[2],{PrintError=>0});
if (!$dbh) {
 print "Can't connect to database " . DBI->errstr . "\n";
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
 print "Can't prepare statement " . $dbh->errstr . "\n";
 exit(3);
}

my $dbe = $dbs->execute();
if (!$dbe) {
 print "Can't execute statement" . $dbh->errstr . "\n";
 exit(3);
}

my($host, $service, $w1, $c1, $w2, $c2, $v1, $v2, $info, $ret);
$dbs->bind_columns(undef, \$host, \$service, \$w1, \$c1, \$w2, \$c2, \$v1, \$v2, \$info);

while($dbs->fetch()) {
 $ret = 0;

 if (range->check_range($w1,$v1)) {
  $ret = 1;
 }
  
 if (range->check_range($w2,$v2)) {
  $ret = 1;
 }

 if (range->check_range($c1,$v1)) {
  $ret = 2;
 }

 if (range->check_range($c2,$v2)) {
  $ret = 2;
 }

 open(my $OUTFILE,">>$cmd_file");
 print $OUTFILE "[" . time() . "] PROCESS_SERVICE_CHECK_RESULT;$host;$service;$ret;$info\n";
 close($OUTFILE);
}

if ($DBI::err) {
 print "Fetch error: " . $dbh->errstr . "\n";
 exit(3);
}

$dbs->finish;
$dbh->disconnect;

print "OK\n";
exit(0);
