#!/usr/bin/perl -w

# 0 host
# 1 username
# 2 public key file
# 3 private key file
# 4 command file
# 5 match string
# 6 label
# 7 param 1
# 8 param 2

use strict;

use lib "/monitor/icinga/libexec/lib/perl";
use lib "/monitor/icinga/libexec";

use range;
use Net::SSH2;

if (!defined($ARGV[7])) {
 $ARGV[7] = "?";
}

if (!defined($ARGV[8])) {
 $ARGV[8] = "?";
}

open(INFILE,"<$ARGV[4]");
my @cmd = <INFILE>;
close(INFILE);

my $cmdstr = join('',@cmd);
$cmdstr =~ s/\?1/$ARGV[7]/g;
$cmdstr =~ s/\?2/$ARGV[8]/g;
$cmdstr =~ s/\?/$ARGV[7]/g;
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
#while (my $line = <$chan>) { chomp $line; print "$line\n"; } 
my $ret = <$chan>;
if (!$ret) {
 print "Timeout\n";
 exit(3);
}

chomp($ret);

if ($ret !~ /$ARGV[5]/)
 {
  print "UNKNOWN: String <" . $ARGV[5] . "> not found\n";
  exit(3);
 }

$chan->close();
$ssh->disconnect();

print "OK: $ARGV[6]=$ret|$ARGV[6]=$ret\n";
exit(0);
