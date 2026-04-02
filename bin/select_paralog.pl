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
my %THRESHOLD;
my %PARALOG;
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
    my $paralogy = 100;
    if ($cross_species_score) {
        $paralogy = $score / $cross_species_score;
    }
    if ($THRESHOLD{$gene1} &&
        $THRESHOLD{$gene1} > $score) {
        next;
    }
    if (! defined $PARALOG{$gene1}) {
        $PARALOG{$gene1} = "";
    }
    if ($paralogy >= 1) {
        if ($PARALOG{$gene1}) {
            $PARALOG{$gene1} .= ",$gene2";
        } else {
            $PARALOG{$gene1} = $gene2;
        }
    }
    if ($paralogy < 1) {
        $THRESHOLD{$gene1} = $score;
    }
    print $_,  "\t", $paralogy;

    print "\t";
    if ($paralogy < 1) {
        print $PARALOG{$gene1};
    } else {
        print "";
    }

    print "\n";
}
close(INTRA_SPECIES);
