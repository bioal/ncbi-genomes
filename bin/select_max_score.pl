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

my %SCORE;
my %RESULT;
while (<>) {
    chomp;
    my @f = split(/\t/, $_, -1);
    my $geneid1 = $f[0];
    my $geneid2 = $f[1];
    my $score = $f[-1];
    if (!$SCORE{"$geneid1\t$geneid2"}) {
        $SCORE{"$geneid1\t$geneid2"} = $score;
        $RESULT{"$geneid1\t$geneid2"} = $_;
    } elsif ($score > $SCORE{"$geneid1\t$geneid2"}) {
        $SCORE{"$geneid1\t$geneid2"} = $score;
        $RESULT{"$geneid1\t$geneid2"} = $_;
    }
}

foreach my $key (sort { $SCORE{$b} <=> $SCORE{$a} } keys %SCORE) {
    print "$RESULT{$key}\n";
}
