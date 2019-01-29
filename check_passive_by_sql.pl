#!/usr/bin/perl -wT

use lib qw(/monitor/icinga/libexec/lib/perl);

use DBI;
#use Fcntl qw(:flock SEEK_END);

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

my($host, $service, $ret, $info);
$dbs->bind_columns(undef, \$host, \$service, \$ret, \$info);

#open(my $OUTFILE,">>$cmd_file");
#flock($OUTFILE, LOCK_EX);
#$OUTFILE->autoflush(1);
#seek($OUTFILE, 0, SEEK_END);
while($dbs->fetch()) {
 open(my $OUTFILE,">>$cmd_file");
 print $OUTFILE "[" . time() . "] PROCESS_SERVICE_CHECK_RESULT;$host;$service;$ret;$info\n";
# print "[" . time() . "] PROCESS_SERVICE_CHECK_RESULT;$host;$service;$ret;$info\n";
 close($OUTFILE);
}
if ($DBI::err) {
 print "Fetch error: " . $dbh->errstr . "\n";
 exit(3);
}
#flock($OUTFILE, LOCK_UN);
#close($OUTFILE);

$dbs->finish;
$dbh->disconnect;

print "OK\n";
exit(0);
