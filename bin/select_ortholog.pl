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

my %MAX_SCORE;
my %PARALOG_SCORE;
open(PARALOG, "$PARALOG") || die "$!";
while (<PARALOG>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $score = $f[11];
    my $paralogy = $f[12];
    if (!$MAX_SCORE{$geneid1} || $score > $MAX_SCORE{$geneid1}) {
        $MAX_SCORE{$geneid1} = $score;
    }
    if ($paralogy <= 1) {
        $PARALOG_SCORE{$geneid1} = $score;
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
    my $orthology_score = get_orthology_score($score, $MAX_SCORE{$geneid1});
    my $orthology_score_2 = get_orthology_score($score, $PARALOG_SCORE{$geneid1});
    print join("\t", @f, $orthology_score, $orthology_score_2), "\n";
}
close(HOMOLOG);

################################################################################
### Function ###################################################################
################################################################################

sub get_orthology_score {
    my ($score, $paralog_score) = @_;

    my $orthology_score = 1000;
    if ($paralog_score) {
        $orthology_score = $score / $paralog_score;
    }

    return $orthology_score;
}
