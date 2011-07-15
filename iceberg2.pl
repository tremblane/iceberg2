#!/usr/local/bin/perl

use lib '/ws/jadew-rtp/perllib';
use WWW::Mechanize;
use XML::Simple;
use Data::Dumper;

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

#print out the staffing numbers
print "                             Staff Avail  Talk  Idle\n";
print "                             ===== ===== ===== =====\n";
foreach my $skill (sort keys %staffedskills) {
	$staffedcount = $staffedskills{$skill};
	if ($talkingskills{$skill}) {
		$talkingcount = $talkingskills{$skill};
	} else {
		$talkingcount = 0;
	}
	if ($idleskills{$skill}) {
		$idlecount = $idleskills{$skill};
	} else {
		$idlecount = 0;
	}
	if ($readyskills{$skill}) {
		$readycount = $readyskills{$skill};
	} else {
		$readycount = 0;
	}
	printf ("%-27s %5d %5d %5d %5d\n",$skill,$staffedcount,$readycount,$talkingcount,$idlecount);
}

