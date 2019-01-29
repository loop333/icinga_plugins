#!/usr/bin/perl -w

# 0 host
# 1 username
# 2 public key file
# 3 private key file
# 4 command file
# 5 label
# 6 warning level
# 7 critical level
# 8 parameter

use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use Net::SSH2;

$ARGV[0] = "srv-ium1";
$ARGV[1] = "ium";
$ARGV[2] = "/monitor/icinga/etc/id_rsa.pub";
$ARGV[3] = "/monitor/icinga/etc/id_rsa";
$ARGV[4] = "/monitor/icinga/etc/sh/test.sh";
$ARGV[5] = "LABEL";
$ARGV[6] = "0";
$ARGV[7] = "0";
$ARGV[8] = "?";

if (!defined($ARGV[8])) {
 $ARGV[8] = "?";
 }

open(INFILE,"<$ARGV[4]");
my @cmd = <INFILE>;
close(INFILE);

my $cmdstr = join('',@cmd);
$cmdstr =~ s/\?/$ARGV[8]/g;
#print "$cmdstr\n";
#exit(0);

my $ssh = Net::SSH2->new();
#$ssh->debug(1);
if (!$ssh->connect($ARGV[0])) {
 print "Can't connect: $!\n";
 exit(3);
}

if (!$ssh->auth_publickey($ARGV[1],$ARGV[2],$ARGV[3])) {
 print "Can't authenticate: $!\n";
 exit(3);
}

my $chan = $ssh->channel();
if (!$chan->exec($cmdstr)) {
 print "Can't exec: $!\n";
 exit(3);
}

my @poll = {handle=>$chan,events=>['in']};
$ssh->poll(10000,\@poll);
#$poll[0]->{revents}->{in};
#while (<$chan>) {print}
while (my $line = <$chan>) { chomp $line; print "$line\n"; }
my $ret = <$chan>;
if (!$ret) {
 print "Timeout\n";
 exit(3);
}

chomp($ret);

$chan->close();
$ssh->disconnect();

$ret =~ s/,/./;

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
