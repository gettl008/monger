#! /usr/bin/perl

use warnings;
use strict;
use Getopt::Std;
use constant USAGE =><<END;

SYNOPSIS:

combineHTSeqCounts.pl [-a countfile1] [-b countfile2]

DESCRIPTION:

Removes unlikely duplicate alignments based on surrounding alignments and BLAT alignment evidence

OPTIONS:
	-a	[FILE]	Output gene counts from htseq
	-b	[FILE]	Output gene counts from htseq
	-o	[FILE]	Output file [default=STDOUT]
 	-h	Prints this help.

AUTHOR:

Noah Gettle

COPYRIGHT:

This program is free software. You may copy and redistribute it under
the same terms as Perl itself.

END


##########################################
###### SANITY CHECK #####
my %opts;
getopts("a:b:o:h", \%opts);

if ( (!(defined $opts{a})) or (!(defined $opts{b})) or (defined $opts{h}) ) {
	die USAGE;
}

##########################################

open (FILE1, $opts{a})  or die "\n\nCannot open file $opts{a}\n\n";
open (FILE2, $opts{b})  or die "\n\nCannot open file $opts{b}\n\n";
if (defined $opts{o}){
	open (OUTFILE, '>'.$opts{o})  or die "\n\nCannot write to  file $opts{o}\n\n";
}

while (defined(my $lineA = <FILE1>) and defined(my $lineB = <FILE2>)){
	my @splitA = split(/\s/, $lineA);
	my @splitB = split(/\s/, $lineB);
	if ($splitA[0] ne $splitB[0]){
		die "\n\nRegions in count files don't match. Make sure the same GFF was used for both.\n\n".USAGE;
	}
	my $sum = $splitA[1] + $splitB[1];
	if (defined $opts{o}){
		print OUTFILE "$splitA[0]\t$sum\n";
	} else {print "$splitA[0]\t$sum\n"}
}