#! /usr/bin/env perl

use warnings;
use strict;
use Getopt::Std;
use Cwd;
use File::Basename;
use constant USAGE =><<END;

SYNOPSIS:

findpairs.pl [-i file_list] [-p pair_number_position] [-o output_file]

DESCRIPTION:

Take in a list of files and find output list of pairs and basenames.

OPTIONS:
	-i	[STR]	Quoted list of input files to parse for pairs and singletons associated with pairs.
	-p	[NUM]	Position relative to end in basename of each file containing indicator of pair number [1].
	-o	[FILE]	Output file [default=STDOUT]
 	-h			Prints this help.

AUTHOR:

Noah Gettle

COPYRIGHT:

This program is free software. You may copy and redistribute it under
the same terms as Perl itself.

END


my %opts;
getopts("i:p:o:h", \%opts);

if ((!(defined $opts{i})) or (defined $opts{h})){
	die USAGE;
}

my $pos = 1;
if (defined $opts{p}) {
	$pos = $opts{p};
}

my @input_array = split(/\s+/, $opts{i});
while ($input_array[0] eq "" ){
	shift @input_array;
}
my %pair_index;
my $length=0;
foreach my $file (@input_array) {
	my $base = basename($file);
	my $dir = dirname($file);
	my @split_base = split(/[\_\.]/, $base);																															
	pop @split_base;
	my $position = scalar(@split_base) - $pos;
	splice(@split_base, $position, 1);
	my $basebase = join("_", @split_base);
	push(@{ $pair_index{"$dir/$basebase"}}, $file);
	# print STDERR "$file\n";
}

if (defined $opts{o}){
	open (OUT, '>'.$opts{o})  or die "\n\nCannot write to  file $opts{o}\n\n";	
}

foreach my $fileset (keys(%pair_index)){
	my $name = basename($fileset);
	# while (scalar @{$pair_index{$fileset}} < 3 ){
	# 	push (@{$pair_index{$fileset}}, "-");
	# }
	if (scalar @{$pair_index{$fileset}} > 3){
		print STDERR "WARNING: More than three files found with basename $fileset. Ignoring set..."
	} else {
		push (@{$pair_index{$fileset}}, $name);
		my $outline = join ("\t", @{$pair_index{$fileset}});
		if (defined $opts{o}){
			print OUT "$outline\n";
		} else {
			print "$outline\n";
		}
	}
}
