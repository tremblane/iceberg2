#!/usr/local/bin/perl

use lib '/ws/jadew-rtp/perllib';
use WWW::Mechanize;

my $username = $ENV{'USER'};
#my $url = "http://wwwin-tools.cisco.com/GTRC/ICE/servlet/iceberg5.obtainMasterData?agentID=$username";
my $url = "http://wwwin.cisco.com/cgi-bin/support/tools/iceberg6/iceberg6_buildxml.cgi?agentid=$username";
my $tempfile = "/tmp/iceberg-$username.xml";

print "CEC password for $username: ";
system("stty -echo");
my $password = <STDIN>;
print "\n";
chomp($password);
system("stty echo");

my $mech = WWW::Mechanize->new();
$mech->credentials( $username => $password );
print "Fetching page\n";
eval { $mech->get($url); };

#$html_page = $mech->content;
#print "$html_page\n";

if (-e $tempfile) {
	unlink ($tempfile);
}

open (OUT, ">$tempfile");
print OUT $mech->content;
close(OUT);

#test comment
