#! /usr/bin/env perl

use warnings;
use strict;
use Getopt::Std;
use Cwd;
use File::Basename;
use constant USAGE =><<END;

SYNOPSIS:

parseMongerScript.pl [-i input] [-a mongergroups] [-o output]

DESCRIPTION:

Takes a MongerScript and creates bash executable file containing relevant variables.

OPTIONS:
	-i	[FILE]	Input MongerScript
	-a	[STR]	Main Monger groups in script to subset [ALL] (should be in quotes)
	-o 	[FILE]	Output file [default=STDOUT]
 	-h			Prints this help.

AUTHOR:

Noah Gettle

COPYRIGHT:

This program is free software. You may copy and redistribute it under
the same terms as Perl itself.

END

my %opts;
getopts("i:a:o:h", \%opts);

if ((!(defined $opts{i})) or (defined $opts{h}) ) {
	die USAGE;
}

open (SCRIPT, $opts{i})  or die "\n\nCannot open MongerScript $opts{i}\n\n";
if (defined $opts{o}){
	open (OUT, '>'.$opts{o}) or die "\n\nCannot write to  file $opts{o}\n\n";
	print OUT "#!/usr/bin/env bash\n";
} else {
	print "#!/usr/bin/env bash\n";
}

my %subset_hash;
if (defined $opts{a}){
	my @subset_array = split(/\s+/, $opts{a});
	for my $subgroup (@subset_array){
		if ($subgroup ne ""){
			$subset_hash{"$subgroup:"} = "";
		}
	}
}

while (my $scriptline = <SCRIPT>){
	if (!($scriptline =~ /^[#\[\]\s]/)){
		chomp $scriptline;
		if ((defined $subset_hash{$scriptline}) or (! (defined $opts{a}))){
			my $start = 0;
			while (my $subscriptline = <SCRIPT>){
				if (($start == 0) and ($subscriptline =~ /^\[/)){
					$start = 1;
				} elsif ($start == 1){
					if ($subscriptline =~ /^\]/){
						last;
					} else {
						$subscriptline =~ s/^\s*//;
						if (!($subscriptline =~ /=/)){
							chomp $subscriptline;
							$subscriptline = "$subscriptline=\n";
						}
						if (defined $opts{o}){
							print OUT "$subscriptline"
						} else {
							print "$subscriptline"
						}
					}
				}
			}
		}
	}
}