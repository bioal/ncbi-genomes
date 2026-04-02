#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM HOMOLOG PARALOG
";

my %OPT;
getopts('', \%OPT);

if (@ARGV != 2) {
    print STDERR $USAGE;
    exit 1;
}
my ($HOMOLOG, $PARALOG) = @ARGV;

my %THRESHOLD_SCORE;
my %LOWER_THRESHOLD;
my %PARALOGS;
open(PARALOG, "$PARALOG") || die "$!";
while (<PARALOG>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $score = $f[11];
    my $paralogy = $f[12];
    my $paralogs = $f[13];
    if (!$THRESHOLD_SCORE{$geneid1} || $score > $THRESHOLD_SCORE{$geneid1}) {
        $THRESHOLD_SCORE{$geneid1} = $score;
    }
    if ($paralogy <= 1) {
        $LOWER_THRESHOLD{$geneid1} = $score;
    }
    if ($paralogs) {
        $PARALOGS{$geneid1} = $paralogs;
    }
}
close(PARALOG);

my %ORTHOLOG_SCORE;
open(HOMOLOG, "$HOMOLOG") || die "$!";
while (<HOMOLOG>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $geneid2 = $f[1];
    my $score = $f[11];
    my $orthology = get_orthology_score($score, $THRESHOLD_SCORE{$geneid1});
    my $grouped_orthology = get_orthology_score($score, $LOWER_THRESHOLD{$geneid1});
    print join("\t", @f, $orthology, $grouped_orthology);

    print "\t";
    if ($PARALOGS{$geneid1}) {
        print $PARALOGS{$geneid1};
    }

    print "\n";
}
close(HOMOLOG);

################################################################################
### Function ###################################################################
################################################################################

sub get_orthology_score {
    my ($score, $threshold_score) = @_;

    my $orthology = 1000;
    if ($threshold_score) {
        $orthology = $score / $threshold_score;
    }

    return $orthology;
}
