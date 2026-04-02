#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($INTRA_SPECIES, $CROSS_SPECIES_SCORE) = @ARGV;

my %CROSS_SPECIES_SCORE;
open(CROSS_SPECIES_SCORE, "$CROSS_SPECIES_SCORE") || die "$!";
while (<CROSS_SPECIES_SCORE>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $bit_score = $f[11];
    if (!$CROSS_SPECIES_SCORE{$gene1}) {
        $CROSS_SPECIES_SCORE{$gene1} = $bit_score;
    }
}
close(CROSS_SPECIES_SCORE);

open(INTRA_SPECIES, "$INTRA_SPECIES") || die "$!";
my %PRINTED_GENE_WITH_SCORE;
while (<INTRA_SPECIES>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $gene1 = $f[0];
    my $gene2 = $f[1];
    my $score = $f[-1];
    if ($gene1 eq $gene2) {
        next;  # Skip self-comparisons
    }
    my $cross_species_score = $CROSS_SPECIES_SCORE{$gene1};
    my $paralogy_score = 100;
    if ($cross_species_score) {
        $paralogy_score = $score / $cross_species_score;
    }
    if ($PRINTED_GENE_WITH_SCORE{$gene1} &&
        $PRINTED_GENE_WITH_SCORE{$gene1} > $score) {
        next;
    }
    print $_,  "\t", $paralogy_score, "\n";
    if ($paralogy_score < 1) {
        $PRINTED_GENE_WITH_SCORE{$gene1} = $score;
    }
}
close(INTRA_SPECIES);
