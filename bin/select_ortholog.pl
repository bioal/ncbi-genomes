#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM PARALOG
";

my %OPT;
getopts('', \%OPT);

if (@ARGV != 1) {
    print STDERR $USAGE;
    exit 1;
}
my ($PARALOG) = @ARGV;

my %PARALOG_SCORE;
open(PARALOG, "$PARALOG") || die "$!";
while (<PARALOG>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $score = $f[-1];
    $PARALOG_SCORE{$geneid1} = $score;
}
close(PARALOG);

my %ORTHOLOG_SCORE;
while (<STDIN>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $geneid2 = $f[1];
    my $score = $f[-1];
    my $ortholog_score = 1000;
    if ($PARALOG_SCORE{$geneid1}) {
        if ($score > $PARALOG_SCORE{$geneid1}) {
            $ortholog_score = $score / $PARALOG_SCORE{$geneid1};
        } else {
            next;
        }
    }
    print join("\t", @f, $ortholog_score), "\n";
}
