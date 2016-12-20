#! /usr/bin/perl

use warnings;
use strict;
use Getopt::Std;
use constant USAGE =><<END;

SYNOPSIS:

GFF3toGTF.pl [-g input_gff]

DESCRIPTION:

Convert GFF3 to GTF format

OPTIONS:
	-g	Input GFF3 annotation file
	-o	Output file [default=STDOUT]
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
getopts("g:o:h", \%opts);

if ( (!(defined $opts{g})) or (defined $opts{h}) ) {
	die USAGE;
}

open (GFF, $opts{g})  or die "\n\nCannot open fasta file $opts{g}\n\n";

if (defined $opts{o}){
	open (OUTFILE, '>'.$opts{o})  or die "\n\nCannot write to  file $opts{o}\n\n";
}

###########################################

my $gene;
my @cds_array;
my $index = 0;
my $strand;
while (my $line = <GFF>){
	if (!($line =~ /^#/)){
		if ($line =~ /\tgene\t/){
			if ($index > 0){
				my $cds_num = scalar(@cds_array) - 1;
				my @splitline;
				my $start_codon;
				my $stop_codon;
				my $previous_length = 0;
				my $frame = 0;
				### POSITIVE STRANDED CDS ###
				if ($strand eq "+"){
					my $cdsIndex = 0;
					my $previous_end;
					while($cdsIndex <= $cds_num){
						@splitline = split(/[\t;=]/, $cds_array[$cdsIndex]);
						my $stop = $splitline[4];
						$previous_end = $splitline[4];
						$frame = 3 - (($previous_length - $frame) % 3);
						### ESTABLISH STOP CODON AND NEW END FOR LAST CDS ###
						if ($cdsIndex == $cds_num){
							my $tail_length = $splitline[4] - $splitline[3] + 1;
							if ($tail_length < 3){
								my $codon_extra = 2 - $tail_length;
								$stop_codon = ($previous_end -$codon_extra)."\t".$previous_end."-".$splitline[3]."\t".$splitline[4];
								$stop = 0;
							} else {
								$stop_codon = ($splitline[4] - 2)."\t".$splitline[4];
								$stop = $splitline[4] - 3;
							}							
						}
						### ESTABLISH START CODON FROM FIRST CDS ###
						if ($cdsIndex == 0){						
							$frame = 0;
							$previous_length = $splitline[4] - $splitline[3] + 1;
							if ($previous_length < 3){
								my @splitnext = split(/[\t;=]/, $cds_array[$cdsIndex + 1]);
								my $codon_extra = 2 - $previous_length;
								$start_codon = $splitline[3]."\t".$splitline[4]."-".$splitnext[3]."\t".($splitnext[3] + $codon_extra);
							} else {
								$start_codon = $splitline[3]."\t".($splitline[3] + 2);
							}
						} else {
							$previous_length = $splitline[4] - $splitline[3] + 1;
							if (( $cdsIndex + 1) == $cds_num){
								my @splitnext = split(/[\t;=]/, $cds_array[$cdsIndex + 1]);
								my $nextlength = $splitnext[4] - $splitnext[3] + 1;
								if ($nextlength < 3){
									$stop = $splitline[4] - ( 3 - $nextlength);
								}
							}
						}
						if ($stop != 0){
							print OUTFILE "$splitline[0]\t$splitline[1]\tCDS\t$splitline[3]\t$stop\t.\t$strand\t$frame\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";
						}
						$cdsIndex++;
					}
				}
				### NEGATIVE STRANDED CDS ###
				if ($strand eq "-"){
					my $cdsIndex = $cds_num;
					my $previous_end;
					while($cdsIndex >= 0){
						@splitline = split(/[\t;=]/, $cds_array[$cdsIndex]);
						my $stop = $splitline[3];
						$previous_end = $splitline[3];
						$frame = 3 - (($previous_length - $frame) % 3);
						### ESTABLISH STOP CODON AND NEW END FOR LAST CDS ###
						if ($cdsIndex == 0){
							my $tail_length = $splitline[4] - $splitline[3] + 1;
							if ($tail_length < 3){
								my $codon_extra = 2 - $tail_length;
								$stop_codon = $splitline[3]."\t".$splitline[4]."-".$previous_end."\t".($previous_end + $codon_extra);
								$stop = 0;
							} else {
								$stop_codon = $splitline[3]."\t".($splitline[3] + 2);
								$stop = $splitline[3] + 3;
							}							
						}
						### ESTABLISH START CODON FROM FIRST CDS ###
						if ($cdsIndex == $cds_num){						
							$frame = 0;
							$previous_length = $splitline[4] - $splitline[3] + 1;
							if ($previous_length < 3){
								my @splitnext = split(/[\t;=]/, $cds_array[$cdsIndex - 1]);
								my $codon_extra = 2 - $previous_length;
								$start_codon = ($splitnext[4] - $codon_extra)."\t".$splitnext[4]."-".$splitline[3]."\t".$splitline[4];
							} else {
								$start_codon = ($splitline[4] - 2)."\t".$splitline[4];
							}
						} else {
							$previous_length = $splitline[4] - $splitline[3] + 1;
							if (( $cdsIndex - 1) == 0){
								my @splitnext = split(/[\t;=]/, $cds_array[$cdsIndex - 1]);
								my $nextlength = $splitnext[4] - $splitnext[3] + 1;
								if ($nextlength < 3){
									$stop = $splitline[3] + ( 3 - $nextlength);
								}
							}
						}
						if ($stop != 0){
							print OUTFILE "$splitline[0]\t$splitline[1]\tCDS\t$splitline[3]\t$stop\t.\t$strand\t$frame\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";
						}
						$cdsIndex = $cdsIndex - 1;
					}
				}
				my @splitstart = split(/-/, $start_codon);
				my $startnum = scalar(@splitstart) - 1;
				my @splitstop = split(/-/, $stop_codon);
				my $stopnum = scalar(@splitstop) - 1;
				if ($strand eq "+"){
					my $startindex = 0;
					my $startframe;
					while($startindex <= $startnum){
						if ($startindex != 0){
							my @splitrange = split(/\t/, $splitstart[$startindex]);
							my $rangelength = $splitrange[1] - $splitrange[0];
							$startframe = 3 - (($rangelength - $startframe) % 3);
						} else {
							$startframe = 0;
						}
						print OUTFILE "$splitline[0]\t$splitline[1]\tstart_codon\t$splitstart[$startindex]\t.\t$strand\t$startframe\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";
						$startindex++;		
					}
					my $stopindex = 0;
					my $stopframe;
					while($stopindex <= $stopnum){
						if ($stopindex != 0){
							my @splitrange = split(/\t/, $splitstop[$stopindex]);
							my $rangelength = $splitrange[1] - $splitrange[0];
							$stopframe = 3 - (($rangelength - $stopframe) % 3);
						} else {
							$stopframe = 0;
						}
						print OUTFILE "$splitline[0]\t$splitline[1]\tstop_codon\t$splitstop[$stopindex]\t.\t$strand\t$stopframe\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";		
						$stopindex++;
					}
				}
				if ($strand eq "-"){
					my $startindex = $startnum;
					my $startframe;
					while($startindex >= 0){
						if ($startindex != $startnum){
							my @splitrange = split(/\t/, $splitstart[$startindex]);
							my $rangelength = $splitrange[1] - $splitrange[0];
							$startframe = 3 - (($rangelength - $startframe) % 3);
						} else {
							$startframe = 0;
						}
						print OUTFILE "$splitline[0]\t$splitline[1]\tstart_codon\t$splitstart[$startindex]\t.\t$strand\t$startframe\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";		
						$startindex = $startindex - 1;
					}
					my $stopindex = $stopnum;
					my $stopframe;
					while($stopindex >= 0){
						if ($stopindex != $stopnum){
							my @splitrange = split(/\t/, $splitstop[$stopindex]);
							my $rangelength = $splitrange[1] - $splitrange[0];
							$stopframe = 3 - (($rangelength - $stopframe) % 3);
						} else {
							$stopframe = 0;
						}
						print OUTFILE "$splitline[0]\t$splitline[1]\tstop_codon\t$splitstop[$stopindex]\t.\t$strand\t$stopframe\tgene_id \"$gene\"; transcript_id \"$gene.1\";\n";		
						$stopindex = $stopindex - 1;
					}
				}
			}
			my @splitline = split(/[\t;=]/, $line);
			$gene = $splitline[11];
			$strand = $splitline[6];
			@cds_array = ();
			$index++;
		} elsif ($line =~ /\tCDS\t/){
			push @cds_array, $line;
		}		
	}
}


