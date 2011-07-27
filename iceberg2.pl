#!/usr/local/bin/perl

use lib '/ws/jadew-rtp/perllib';
use WWW::Mechanize;
use XML::Simple;
use Data::Dumper;
use Switch;

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
#print "Fetching page\n";
print "\n";
eval { $mech->get($url); };

#$html_page = $mech->content;
#print "$html_page\n";

if (-e $tempfile) {
	unlink ($tempfile);
}

open (OUT, ">$tempfile");
print OUT $mech->content;
close(OUT);

my $simple = XML::Simple->new();
my $tree = $simple->XMLin("$tempfile",ForceArray => 1);

#get staffing count for talking agents
foreach my $analyst (@{$tree->{agentstatus}->[0]->{talking}->[0]->{talkinganalyst}}) {
	my @skills = split /,/, $analyst->{callskills};
	foreach my $skill (@skills) {
		if ($staffedskills{$skill}) {
			$staffedskills{$skill} += 1;
		} else {
			$staffedskills{$skill} = 1;
		}
	}
	if ($talkingskills{$analyst->{talkingon}}) {
		$talkingskills{$analyst->{talkingon}} += 1;
	} else {
		$talkingskills{$analyst->{talkingon}} = 1;
	}
}

#get staffing count for idle agents
foreach my $analyst (@{$tree->{agentstatus}->[0]->{notready}->[0]->{notreadyanalyst}}) {
	my @skills = split /,/, $analyst->{callskills};
	foreach my $skill (@skills) {
		if ($staffedskills{$skill}) {
			$staffedskills{$skill} += 1;
		} else {
			$staffedskills{$skill} = 1;
		}
		if ($idleskills{$skill}) {
			$idleskills{$skill} += 1;
		} else {
			$idleskills{$skill} = 1;
		}
	}
}

#get staffing count for ready agents
foreach my $analyst (@{$tree->{agentstatus}->[0]->{ready}->[0]->{readyanalyst}}) {
	my @skills = split /,/, $analyst->{callskills};
	foreach my $skill (@skills) {
		if ($staffedskills{$skill}) {
			$staffedskills{$skill} += 1;
		} else {
			$staffedskills{$skill} = 1;
		}
		if ($readyskills{$skill}) {
			$readyskills{$skill} += 1;
		} else {
			$readyskills{$skill} = 1;
		}
	}
}

#combine skills into groups
foreach my $skill (sort keys %staffedskills) {
	#set $group based on $skill
	switch ($skill) {
		case /GTRC_DESKTOP/ { $group=" DESKTOP"; }
		case /GTRC_ENG/ { $group=" ENG"; }
		case /GTRC_MAIN/ { $group=" MAIN"; }
		case /GTRC_MOBILITY/ { $group=" MOBILITY"; }
		case /GTRC_T2D_SPA/ { $group=" T2D_SPANISH"; }
		case /GTRC_T2D/ { $group=" T2D"; }
		case /GTRC_VIP/ { $group=" VIP"; }
		case /GTRC_WEBEX/ { $group=" WEBEX"; }
		case /GTRC_PORTUGUESE/ { $group=" PORTUGUESE"; }
		case /GTRC_SPANISH/ { $group=" SPANISH"; }
		case /GTRC_LWR/ { $group=" LWR"; }
		case /GTRC_DR_DESKTOP/ { $group=" DR_DESKTOP"; }
		case /GTRC_MAND_ENG/ { $group=" MANDARIN_ENG"; }
		case /GTRC_MAND/ { $group=" MANDARIN"; }
		else	{ $group=$skill; }
	}

	#initialize $grouped_*{$group} hashes to zero if needed
	if (!defined($grouped_staffed{$group})) { $grouped_staffed{$group}=0; }
	if (!defined($grouped_talking{$group})) { $grouped_talking{$group}=0; }
	if (!defined($grouped_idle{$group})) { $grouped_idle{$group}=0; }
	if (!defined($grouped_ready{$group})) { $grouped_ready{$group}=0; }

	#add to running total for $group
	$grouped_staffed{$group} += $staffedskills{$skill}; #staffedskills should never be null
	if ($talkingskills{$skill}) { $grouped_talking{$group} += $talkingskills{$skill}; }
	if ($idleskills{$skill}) { $grouped_idle{$group} += $idleskills{$skill}; }
	if ($readyskills{$skill}) { $grouped_ready{$group} += $readyskills{$skill}; }
}

#print out the grouped staffing numbers
print "                        Staff Avail  Talk  Idle\n";
print "                        ===== ===== ===== =====\n";
foreach my $group (sort keys %grouped_staffed) {
printf ("%-22s %5d %5d %5d %5d\n",$group,$grouped_staffed{$group},$grouped_ready{$group},$grouped_talking{$group},$grouped_idle{$group});
}

